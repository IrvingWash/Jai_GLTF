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
    animations:   [..]GLTF_Animation;
    buffers:      [..]GLTF_Buffer;
    buffer_views: [..]GLTF_Buffer_View; @JsonName(bufferViews)
    cameras:      [..]GLTF_Camera;
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

    array_free(gltf.accessors);
    array_free(gltf.animations);
    array_free(gltf.buffers);
    array_free(gltf.buffer_views);
    array_free(gltf.cameras);
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

GLTF_Accessor :: struct {}

GLTF_Animation :: struct {}

GLTF_Buffer :: struct {}

GLTF_Buffer_View :: struct {}

GLTF_Camera :: struct {}

GLTF_Image :: struct {}

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

    #if FULL_DATA {
        free(asset.copyright);
        free(asset.min_version);
    }

    asset.* = {};
}
