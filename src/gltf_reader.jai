/*
This file reads `.gltf` files and simply parses their data into Jai types.
No manipulations are applied at all.
Everything here is meant for internal use.
*/

/*
@Todo support `sparse` field in `GLTF_Accessor`
@Todo support `animations`
@Todo support `cameras`
@Todo support `weights` in `GLTF_Mesh`
@Todo support `targets` in `GLTF_Mesh.Primitive`
@Todo support `camera` in `GLTF_Node`
@Todo support `skin` in `GLTF_Node`
@Todo support `weights` in `GLTF_Node`
@Todo support `skins`
*/

#scope_module

#import "Basic";
#import "String";
#import "Math";
#import "jaison";

ABSENT: s32 : -1;

GLTF :: struct {
    asset: GLTF_Asset;

    _scene: s32 = ABSENT; @JsonName(scene)

    accessors:    [..]GLTF_Accessor;
    buffers:      [..]GLTF_Buffer;
    buffer_views: [..]GLTF_Buffer_View; @JsonName(bufferViews)
    images:       [..]GLTF_Image;
    materials:    [..]GLTF_Material;
    meshes:       [..]GLTF_Mesh;
    nodes:        [..]GLTF_Node;
    samplers:     [..]GLTF_Sampler;
    scenes:       [..]GLTF_Scene;
    textures:     [..]GLTF_Texture;
}

is_there :: (value: s32) -> bool {
    return value != ABSENT;
}

read_gltf :: (path: string) -> ok: bool, error: string, GLTF {
    assert(is_absolute_path(path), "Path '%' is not an absolute path", path);

    ok, gltf := json_parse_file(path, GLTF);
    if !ok {
        return false, tprint("Failed to parse GLTF JSON data from %", path), gltf;
    }

    return true, "", gltf;
}

release_gltf :: (gltf: *GLTF) {
    destroy_asset(*gltf.asset);

    destroy_accessors(gltf.accessors);
    array_free(gltf.accessors);

    destroy_buffers(gltf.buffers);
    array_free(gltf.buffers);

    destroy_buffer_views(gltf.buffer_views);
    array_free(gltf.buffer_views);

    destroy_images(gltf.images);
    array_free(gltf.images);

    destroy_materials(gltf.materials);
    array_free(gltf.materials);

    destroy_meshes(gltf.meshes);
    array_free(gltf.meshes);

    destroy_nodes(gltf.nodes);
    array_free(gltf.nodes);

    destroy_samplers(gltf.samplers);
    array_free(gltf.samplers);

    destroy_scenes(gltf.scenes);
    array_free(gltf.scenes);

    destroy_textures(gltf.textures);
    array_free(gltf.textures);

    gltf.* = {};
}

GLTF_Asset :: struct {
    version:     string;

    #if FULL_DATA {
        generator:   string;
        copyright:   string;
        min_version: string; @JsonName(minVersion)
    }
}

GLTF_Accessor :: struct {
    _buffer_view:    s32            = ABSENT;   @JsonName(bufferView)
     byte_offset:    s32;                       @JsonName(byteOffset)
     component_type: Component_Type = .UNKNOWN; @JsonName(componentType)
     normalized:     bool;
     count:          s32;
     type:           Accessor_Type  = .UNKNOWN;
     max:            [..]float;
     min:            [..]float;

    #if FULL_DATA {
        name: string;
    }

     Component_Type :: enum s32 #specified {
         UNKNOWN        :: 0;
         BYTE           :: 5120;
         UNSIGNED_BYTE  :: 5121;
         SHORT          :: 5122;
         UNSIGNED_SHORT :: 5123;
         UNSIGNED_INT   :: 5125;
         FLOAT          :: 5126;
     }

     Accessor_Type :: enum {
         UNKNOWN;
         SCALAR;
         VEC2;
         VEC3;
         VEC4;
         MAT2;
         MAT3;
         MAT4;
     }
}

GLTF_Buffer :: struct {
    uri: string;
    byte_length: s32; @JsonName(byteLength)

    #if FULL_DATA {
        name: string;
    }
}

GLTF_Buffer_View :: struct {
     buffer:      s32;
     byte_offset: s32;               @JsonName(byteOffset)
     byte_length: s32;               @JsonName(byteLength)
    _byte_stride: s32    = ABSENT;   @JsonName(byteStride)
     target:      Target = .UNKNOWN; @JsonName(target)

    #if FULL_DATA {
        name: string;
    }

    Target :: enum s32 #specified {
        UNKNOWN              :: 0;
        ARRAY_BUFFER         :: 34962;
        ELEMENT_ARRAY_BUFFER :: 34963;
    }
}

GLTF_Image :: struct {
     uri:         string;
    _buffer_view: s32 = ABSENT; @JsonName(bufferView)
     name:        string;
 
    #if FULL_DATA {
        mime_type: string; @JsonName(mimeType)
    }
}

GLTF_Material :: struct {
    pbr_metallic_roughness: PBR_Metallic_Roughness;            @JsonName(pbrMetallicRoughness)
    normal_texture:         Normal_Texture_Info;               @JsonName(normalTexture)
    occlusion_texture:      Occlusion_Texture_Info;            @JsonName(occlusionTexture)
    emissive_texture:       Texture_Info;                      @JsonName(emissiveTexture)
    emissive_factor:        [3]float;                          @JsonName(emissiveFactor)
    alpha_mode:             Alpha_Mode              = .OPAQUE; @JsonName(alphaMode)
    alpha_cutoff:           float                   = 0.5;     @JsonName(alphaCutoff)
    double_sided:           bool;                              @JsonName(doubleSided)
    name:                   string;

    PBR_Metallic_Roughness :: struct {
        base_color_factor:          [4]float      = float.[1, 1, 1, 1]; @JsonName(baseColorFactor)
        base_color_texture:         Texture_Info;                       @JsonName(baseColorTexture)
        metallic_factor:            float         = 1;                  @JsonName(metallicFactor)
        roughness_factor:           float         = 1;                  @JsonName(roughnessFactor)
        metallic_roughness_texture: Texture_Info;                       @JsonName(metallicRoughnessTexture)
    }

    Normal_Texture_Info :: struct {
        using texture: Texture_Info;

        scale: float = 1;
    }

    Occlusion_Texture_Info :: struct {
        using texture: Texture_Info;

        strength: float = 1;
    }

    Alpha_Mode :: enum {
        UNKNOWN;
        OPAQUE;
        MASK;
        BLEND;
    }

    Texture_Info :: struct {
        _index:     s32 = ABSENT; @JsonName(index)
         tex_coord: s32;          @JsonName(texCoord)
    }
}

GLTF_Mesh :: struct {
    primitives: [..]Primitive;
    name:       string;

    Primitive :: struct {
         attributes: Attributes;
        _indices:    s32         = ABSENT;     @JsonName(indices)
        _material:   s32         = ABSENT;     @JsonName(material)
         mode:       Mode        = .TRIANGLES;
    }

    Attributes :: struct {
        _position:   s32 = ABSENT; @JsonName(POSITION)
        _normal:     s32 = ABSENT; @JsonName(NORMAL)
        _texcoord_0: s32 = ABSENT; @JsonName(TEXCOORD_0)
    }

    Mode :: enum s32 #specified {
        POINTS         :: 0;
        LINES          :: 1;
        LINE_LOOP      :: 2;
        LINE_STRIP     :: 3;
        TRIANGLES      :: 4;
        TRIANGLE_STRIP :: 5;
        TRIANGLE_FAN   :: 6;
    }
}

GLTF_Node :: struct {
     children:    [..]s32;
     matrix:      [16]float = #run Matrix4_Identity.floats;
    _mesh:        s32       = ABSENT;                       @JsonName(mesh)
     rotation:    [4]float  = float.[0, 0, 0, 1];
     scale:       [3]float  = float.[1, 1, 1];
     translation: [3]float;
     name:        string;
}

GLTF_Sampler :: struct {
    mag_filter: Mag_Filter = .UNKNOWN; @JsonName(magFilter)
    min_filter: Min_Filter = .UNKNOWN; @JsonName(minFilter)
    wrap_s:     Wrap_Mode  = .REPEAT;  @JsonName(wrapS)
    wrap_t:     Wrap_Mode  = .REPEAT;  @JsonName(wrapT)
    name:       string;

    Mag_Filter :: enum s32 #specified {
        UNKNOWN :: 0;
        NEAREST :: 9728;
        LINEAR  :: 9729;
    }

    Min_Filter :: enum s32 #specified {
        UNKNOWN                :: 0;
        NEAREST                :: 9728;
        LINEAR                 :: 9729;
        NEAREST_MIPMAP_NEAREST :: 9984;
        LINEAR_MIPMAP_NEAREST  :: 9985;
        NEAREST_MIPMAP_LINEAR  :: 9986;
        LINEAR_MIPMAP_LINEAR   :: 9987;
    }

    Wrap_Mode :: enum s32 #specified {
        CLAMP_TO_EDGE   :: 33071;
        MIRRORED_REPEAT :: 33648;
        REPEAT          :: 10497;
    }
}

GLTF_Scene :: struct {
    nodes: [..]s32;
    name:  string;
}

GLTF_Texture :: struct {
    _sampler: s32     = ABSENT; @JsonName(sampler)
    _source:  s32     = ABSENT; @JsonName(source)
     name:    string;
}



#scope_file

destroy_asset :: (asset: *GLTF_Asset) {
    free(asset.version);

    #if FULL_DATA {
        free(asset.generator);
        free(asset.copyright);
        free(asset.min_version);
    }

    asset.* = {};
}

destroy_accessors :: (accessors: []GLTF_Accessor) {
    for accessor: accessors {
        array_free(accessor.max);
        array_free(accessor.min);

        #if FULL_DATA {
            free(accessor.name);
        }
    }
}

destroy_buffers :: (buffers: []GLTF_Buffer) {
    for buffer: buffers {
        free(buffer.uri);

        #if FULL_DATA {
            free(buffer.name);
        }
    }
}

destroy_buffer_views :: (buffer_views: []GLTF_Buffer_View) {
    #if FULL_DATA {
        for buffer_view: buffer_views {
            free(buffer_view.name);
        }
    }
}

destroy_images :: (images: []GLTF_Image) {
    for image: images {
        free(image.uri);
        free(image.name);

        #if FULL_DATA {
            free(image.mime_type);
        }
    }
}

destroy_materials :: (materials: []GLTF_Material) {
    for material: materials {
        free(material.name);
    }
}

destroy_meshes :: (meshes: []GLTF_Mesh) {
    for mesh: meshes {
        free(mesh.name);

        array_free(mesh.primitives);
    }
}

destroy_nodes :: (nodes: []GLTF_Node) {
    for node: nodes {
        array_free(node.children);
        free(node.name);
    }
}

destroy_samplers :: (samplers: []GLTF_Sampler) {
    for sampler: samplers {
        free(sampler.name);
    }
}

destroy_scenes :: (scenes: []GLTF_Scene) {
    for scene: scenes {
        array_free(scene.nodes);
        free(scene.name);
    }
}

destroy_textures :: (textures: []GLTF_Texture) {
    for texture: textures {
        free(texture.name);
    }
}
