// @Todo support `sparse` field in `GLTF_Accessor`
// @Todo support `animations`
// @Todo support `cameras`

#scope_module

#import "Basic";
#import "String";
#import "File";
#import "jaison";

ABSENT: s32 : -1;

GLTF :: struct {
    #if FULL_DATA {
        asset: GLTF_Asset;
    }

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
    skins:        [..]GLTF_Skin;
    textures:     [..]GLTF_Texture;
}

is_there :: (value: s32) -> bool {
    return value != ABSENT;
}

load_gltf :: (path: string) -> ok: bool, error: string, GLTF {
    gltf: GLTF;

    absolute_path := path;
    if !is_absolute_path(path) {
        absolute_path =, ok := get_absolute_path(path);
        if !ok {
            return false, tprint("Failed to get absolute path for %", path), gltf;
        }
    }

    ok:, gltf = json_parse_file(absolute_path, GLTF);
    if !ok {
        return false, tprint("Failed to parse GLTF JSON data from %", absolute_path), gltf;
    }

    return true, "", gltf;
}

release_gltf :: (gltf: *GLTF) {
    #if FULL_DATA {
        destroy_asset(*gltf.asset);
    }

    destroy_accessors(gltf.accessors);
    array_free(gltf.accessors);

    destroy_buffers(gltf.buffers);
    array_free(gltf.buffers);

    destroy_buffer_views(gltf.buffer_views);
    array_free(gltf.buffer_views);

    destroy_images(gltf.images);
    array_free(gltf.images);

    array_free(gltf.materials);
    array_free(gltf.meshes);
    array_free(gltf.nodes);
    array_free(gltf.samplers);
    array_free(gltf.scenes);
    array_free(gltf.skins);
    array_free(gltf.textures);

    gltf.* = {};
}

GLTF_Asset :: struct {
    generator:   string;
    version:     string;
    copyright:   string;
    min_version: string; @JsonName(minVersion)
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
    byte_length: s32;

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
 
    #if FULL_DATA {
        mime_type: string; @JsonName(mimeType)
        name:      string;
    }
}

GLTF_Material :: struct {}

GLTF_Mesh :: struct {}

GLTF_Node :: struct {}

GLTF_Sampler :: struct {}

GLTF_Scene :: struct {}

GLTF_Skin :: struct {}

GLTF_Texture :: struct {}



#scope_file

destroy_asset :: (asset: *GLTF_Asset) {
    free(asset.generator);
    free(asset.version);
    free(asset.copyright);
    free(asset.min_version);

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

        #if FULL_DATA {
            free(image.mime_type);
            free(image.name);
        }
    }
}
