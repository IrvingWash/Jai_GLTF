/*
This file parses a `.gltf` file into a `Scene`.
The `Scene` is meant to be consumable into a rendering application.
*/

#import "Basic";
#import "File";
#import "String";

Scene :: struct {
    name:   string;
    nodes:  [..]Node;
    meshes: [..]Mesh;
}

Node :: struct {
    name: string;

    parent_index:     s32      = -1;
    children_indices: [..]s32;

    first_mesh_index: s32 = -1;
    mesh_count:       s32;

    local_transform: Matrix4 = Matrix4_Identity; // Row-major
}

Mesh :: struct {
    name: string;

    vertices: [..]Vertex;
    indices:  [..]u32;

    material: Material;

    min_position: Vector3;
    max_position: Vector3;
}

Vertex :: struct {
    position: Vector3;
    normal:   Vector3 = { 0, 0, 1 };
    uv:       Vector2;
}

Material :: struct {
    name: string;

    // @Incomplete
}

load_scene :: (gltf_path: string) -> ok: bool, error: string, Scene {
    scene: Scene;

    // =========================================================================
    // Preparing
    // =========================================================================

    absolute_path := gltf_path;
    if !is_absolute_path(gltf_path) {
        absolute_path =, ok := get_absolute_path(gltf_path);
        if !ok {
            return false,
                tprint(
                    "Failed to get absotlute path for '%'",
                    gltf_path,
                ),
                scene;
        }
    }

    ok, error, gltf := read_gltf(absolute_path);
    if !ok {
        return false, error, scene;
    }
    defer release_gltf(*gltf);

    if !is_supported_version(gltf) {
        return false,
            tprint(
                "File at '%' is GLTF version '%', but only % are supported supported",
                absolute_path,
                gltf.asset.version,
                SUPPORTED_GLTF_VERSIONS,
            ),
            scene;
    }

    if gltf.scenes.count != 1 {
        return false,
            tprint(
                "File at '%' contains % scenes, but only 1 scene is supported",
                absolute_path,
                gltf.scenes.count,
            ),
            scene;
    }

    root_path := path_strip_filename(absolute_path);

    ok =, error =, loaded_gltf_buffers := load_gltf_buffers(gltf, root_path);
    defer release_loaded_gltf_buffers(loaded_gltf_buffers);
    if !ok {
        return false, error, scene;
    }

    // =========================================================================
    // Parsing
    // =========================================================================

    scene.name = copy_string(gltf.scenes[0].name);
    array_reserve(*scene.nodes, gltf.nodes.count);
    array_reserve(*scene.meshes, get_gltf_primitives_count(gltf));

    for gltf_node: gltf.nodes {
        // @Incomplete
    }

    return true, "", scene;
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
    }
    array_free(scene.meshes);

    scene.* = {};
}



#scope_file

Loaded_GLTF_Buffer :: #type,isa string;

SUPPORTED_GLTF_VERSIONS :: string.["2.0"];

is_supported_version :: (gltf: GLTF) -> bool {
    ok := array_find(SUPPORTED_GLTF_VERSIONS, gltf.asset.version);

    return ok;
}

load_gltf_buffers :: (gltf: GLTF, root_path: string) -> ok: bool, error: string, [..]Loaded_GLTF_Buffer {
    buffers: [..]Loaded_GLTF_Buffer;

    for gltf_buffer: gltf.buffers {
        absolute_buffer_path := path_join(root_path, gltf_buffer.uri,, temp);
        bytes, ok := read_entire_file(absolute_buffer_path);
        if !ok {
            return false, tprint("Failed to read buffer from %", absolute_buffer_path), buffers;
        }

        array_add(
            *buffers,
            cast(Loaded_GLTF_Buffer, bytes),
        );
    }

    return true, "", buffers;
}

release_loaded_gltf_buffers :: (buffers: [..]Loaded_GLTF_Buffer) {
    for buffer: buffers {
        free(buffer);
    }

    array_free(buffers);
}

get_gltf_primitives_count :: (gltf: GLTF) -> u32 {
    result: u32;

    for mesh: gltf.meshes {
        for primitive: mesh.primitives {
            result += 1;
        }
    }

    return result;
}

#load "gltf_reader.jai";
