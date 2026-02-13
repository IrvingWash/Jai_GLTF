/*
    This file parses a `.gltf` file into a `Scene`.
    The `Scene` is meant to be consumable into a rendering application.
*/

#import "Basic";
#import "File";
#import "String";
FP :: #import "Flat_Pool";

Scene :: struct {
    name:   string;

    nodes:  [..]Node;
    meshes: [..]Mesh;
}

Node :: struct {
    name: string;

    parent_index:     s32      = ABSENT;
    children_indices: [..]s32;

    first_mesh_index: s32 = ABSENT;
    mesh_count:       s32;

    local_transform: Matrix4 = Matrix4_Identity; // Row-major
}

// We map GLTF primitives to meshes, as having the separation between a mesh and its primitives doesn't make a lot of sense for me.
Mesh :: struct {
    name: string;

    vertices: [..]Vertex;
    indices:  [..]u32;
    mode:     Mode = .TRIANGLES;

    material: Material;

    min_position: Vector3;
    max_position: Vector3;

    Mode :: GLTF_Mesh.Primitive.Mode;
}

Vertex :: struct {
    position: Vector3;
    normal:   Vector3 = { 0, 0, 1 };
    uv:       Vector2;
}

Material :: struct {
    name: string;

    double_sided: bool;
    alpha_mode:   Alpha_Mode = .OPAQUE;
    alpha_cutoff: float      = 0.5;

    pbr_metallic_roughness: PBR_Metallic_Roughness;
    normal_texture:         Normal_Texture;
    occlusion_texture:      Occlusion_Texture;
    emissive_texture:       Emissive_Texture;

    Alpha_Mode :: #type GLTF_Material.Alpha_Mode;

    PBR_Metallic_Roughness :: struct {
        base_color_factor:  Vector4 = { 1, 1, 1, 1 };
        base_color_texture: Texture;

        metallic_factor:            float    = 1;
        roughness_factor:           float    = 1;
        metallic_roughness_texture: Texture;
    }

    Normal_Texture :: struct {
        scale:   float    = 1;
        texture: Texture;
    }

    Occlusion_Texture :: struct {
        strength: float    = 1;
        texture:  Texture;
    }

    Emissive_Texture :: struct {
        factor:  Vector3;
        texture: Texture;
    }

    Texture :: struct {
        image_path: string;

        mag_filter: Mag_Filter = .UNKNOWN;
        min_filter: Min_Filter = .UNKNOWN;
        wrap_s:     Wrap_Mode  = .REPEAT;
        wrap_t:     Wrap_Mode  = .REPEAT;

        Mag_Filter :: #type GLTF_Sampler.Mag_Filter;
        Min_Filter :: #type GLTF_Sampler.Min_Filter;
        Wrap_Mode  :: #type GLTF_Sampler.Wrap_Mode;
    }
}

load_scene :: (gltf_path: string) -> error: string, Scene {
    pool: FP.Flat_Pool;
    pool_allocator: Allocator = {
        proc = FP.flat_pool_allocator_proc,
        data = *pool,
    };
    defer {
        FP.reset(*pool);
        FP.fini(*pool);
    }

    scene: Scene;

    // =========================================================================
    // Preparing
    // =========================================================================

    absolute_path := gltf_path;
    if !is_absolute_path(gltf_path) {
        absolute_path =, ok := get_absolute_path(gltf_path,, pool_allocator);
        if !ok {
            return tprint(
                    "Failed to get absolute path for '%'",
                    gltf_path,
                ),
                scene;
        }
    }

    error, gltf := read_gltf(absolute_path,, pool_allocator);
    if error {
        return error, scene;
    }

    if !is_supported_version(gltf) {
        return tprint(
                "File at '%' is GLTF version '%', but only % are supported",
                absolute_path,
                gltf.asset.version,
                SUPPORTED_GLTF_VERSIONS,
            ),
            scene;
    }

    if gltf._scene == ABSENT {
        return tprint(
                "File at '%' doesn't have a default scene",
                absolute_path,
            ),
            scene;
    }

    if gltf.scenes.count != 1 {
        return tprint(
                "File at '%' contains % scenes, but only 1 scene is supported",
                absolute_path,
                gltf.scenes.count,
            ),
            scene;
    }

    root_path := path_strip_filename(absolute_path,, pool_allocator);

    error =, loaded_gltf_buffers := load_gltf_buffers(
        gltf,
        root_path,,
        pool_allocator
    );
    if error {
        return error, scene;
    }

    // =========================================================================
    // Parsing
    // =========================================================================

    gltf_scene := gltf.scenes[gltf._scene];

    scene.name = copy_string(gltf_scene.name);
    // @Todo these reserves are correct situationally because we don't allow multiple scenes.
    // If we had/allowed more scenes, we'd reserve too much memory with the current code.
    array_reserve(*scene.nodes, gltf.nodes.count);
    array_reserve(*scene.meshes, get_gltf_primitives_count(gltf));

    // Parsing the nodes and everything inside them
    for gltf_node_index: gltf_scene.nodes {
        parse_gltf_node(
            gltf,
            gltf_node_index,
            *scene,
            loaded_gltf_buffers,
            root_path,
        );
    }

    return "", scene;
}

release_scene :: (scene: *Scene) {
    free(scene.name);

    for node: scene.nodes {
        free(node.name);
        array_free(node.children_indices);
    }
    array_free(scene.nodes);

    for mesh: scene.meshes {
        free(mesh.name);
        array_free(mesh.vertices);
        array_free(mesh.indices);

        free(mesh.material.name);
        free(mesh.material.pbr_metallic_roughness.base_color_texture.image_path);
        free(mesh.material.pbr_metallic_roughness.metallic_roughness_texture.image_path);
        free(mesh.material.normal_texture.texture.image_path);
        free(mesh.material.occlusion_texture.texture.image_path);
        free(mesh.material.emissive_texture.texture.image_path);
    }
    array_free(scene.meshes);

    scene.* = {};
}



#scope_module

ABSENT: s32 : -1;



#scope_file

/*
gltf_node_index is used to subscript the list of nodes from the GLTF file.
Other indexes, without the "gltf" prefix/postfix are used to subscript the scene.
*/
parse_gltf_node :: (
    gltf:                GLTF,
    gltf_node_index:     s32,
    scene:               *Scene,
    loaded_gltf_buffers: []Loaded_GLTF_Buffer,
    root_path:           string,
    parent_node_index:   s32                   = ABSENT,
) -> parsed_node_index: s32 {
    gltf_node := gltf.nodes[gltf_node_index];

    node: Node = {
        name            = copy_string(gltf_node.name),
        parent_index    = parent_node_index,
        local_transform = extract_gltf_node_transform(gltf_node),
    };

    // =========================================================================
    // Parsing meshes (primitives)
    // =========================================================================
    if gltf_node._mesh != ABSENT {
        gltf_mesh := gltf.meshes[gltf_node._mesh];

        // We are going to add meshes to the scene, so the current count is exactly where the first mesh will be placed.
        node.first_mesh_index = cast(s32, scene.meshes.count);
        // The meshes of this node are placed contiguously. We map GLTF's primitives to our meshes
        node.mesh_count = cast(s32, gltf_mesh.primitives.count);

        common_name := gltf_mesh.name;

        for gltf_primitive: gltf_mesh.primitives {
            array_add(
                *scene.meshes,
                parse_gltf_primitive(
                    gltf,
                    gltf_primitive,
                    loaded_gltf_buffers,
                    root_path,
                    common_name,
                ),
            );
        }
    }

    // At this point we have filled all the info for the node except it's children
    // It would be more readable if we added the node into the scene at the end of this procedure,
    // when we added the children into the node.
    // But that doesn't work because we can correctly get the index of this node inside the scene only now, before parsing child nodes.
    array_add(*scene.nodes, node);

    // =========================================================================
    // Parsing children
    // =========================================================================
    current_node_index := scene.nodes.count - 1;

    for gltf_child_index: gltf_node.children {
        parsed_node_index := parse_gltf_node(
            gltf,
            gltf_child_index,
            scene,
            loaded_gltf_buffers,
            root_path,
            cast(s32, current_node_index),
        );

        array_add(
            *scene.nodes[current_node_index].children_indices,
            parsed_node_index
        );
    }

    return cast(s32, current_node_index);
}

parse_gltf_primitive :: (
    gltf:                GLTF,
    gltf_primitive:      GLTF_Mesh.Primitive,
    loaded_gltf_buffers: []Loaded_GLTF_Buffer,
    root_path:           string,
    common_name:         string,
) -> Mesh {
    mesh: Mesh;

    // @Incomplete

    return mesh;
}

extract_gltf_node_transform :: (gltf_node: GLTF_Node) -> Matrix4 {
    /*
        We don't know what the gltf file contained - the matrix or a TRS set.
        So we proceed in three stages:
        1. See if the matrtix is not an identity matrix.
        If so - it was present in the file, because otherwise GLTF_Reader would return the identity matrix.
        Return the matrix, we're lucky!
        But if it's an identity matrix - we don't know whether it's an actual identity matrix from the file or just the default from the GLTF_Reader.
        We need more evidence.
        2. Now we need to check whether the separate TRS fields were present in the file.
        If we are here, we know that the matrix from the file doesn't transform anything.
        So we check the TRS.
        :If all of them are the defaults too - we just return Matrix_Identity, as we know for sure neither the matrix nor the TRS are trying to transform.
        3. If something from the TRS gang is not at it's default, we know for sure, there is a transformation. We calculate it and return.
    */

    // Step 1
    gltf_node_transform: Matrix4 = ---;
    gltf_node_transform.floats = gltf_node.matrix;
    gltf_node_transform = transpose(gltf_node_transform); // Transpose because Jai has row-major matrices, but the data from gltf comes in column-major.

    if gltf_node_transform != Matrix4_Identity {
        return gltf_node_transform;
    }

    // Step 2
    gltf_node_translation: Vector3;
    gltf_node_rotation:    Quaternion;
    gltf_node_scale:       Vector3;

    gltf_node_translation.component = gltf_node.translation;
    gltf_node_rotation.component    = gltf_node.rotation;
    gltf_node_scale.component       = gltf_node.scale;

    if (
        gltf_node_translation == Vector3.{}
        && gltf_node_scale == Vector3.{ 1, 1, 1 }
        && gltf_node_rotation == Quaternion.{}
    ) {
        return Matrix4_Identity;
    }

    // Step 3
    translation := make_translation_matrix4(gltf_node_translation);
    rotation    := rotation_matrix(Matrix4, gltf_node_rotation);
    _scale      := make_scale_matrix4(gltf_node_scale);

    return translation * rotation * _scale;
}

Loaded_GLTF_Buffer :: #type,isa string;

load_gltf_buffers :: (gltf: GLTF, root_path: string) -> error: string, []Loaded_GLTF_Buffer {
    assert(
        context.allocator.proc == FP.flat_pool_allocator_proc,
        "This procedure expects to allocate into a pool allocator.",
    );

    buffers: [..]Loaded_GLTF_Buffer;

    for gltf_buffer: gltf.buffers {
        absolute_buffer_path := path_join(root_path, gltf_buffer.uri);
        bytes, ok := read_entire_file(absolute_buffer_path);
        if !ok {
            return tprint("Failed to read buffer from %", absolute_buffer_path),
                buffers;
        }

        array_add(
            *buffers,
            cast(Loaded_GLTF_Buffer, bytes),
        );
    }

    return "", buffers;
}

get_gltf_primitives_count :: (gltf: GLTF) -> u32 {
    result: u32;

    for mesh: gltf.meshes {
        result += cast(u32, mesh.primitives.count);
    }

    return result;
}

SUPPORTED_GLTF_VERSIONS :: string.["2.0"];

is_supported_version :: (gltf: GLTF) -> bool {
    ok := array_find(SUPPORTED_GLTF_VERSIONS, gltf.asset.version);

    return ok;
}

#load "gltf_reader.jai";
