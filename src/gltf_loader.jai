#scope_module

#import "Basic";
#import "String";
#import "File";

// https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/Models-core.md
// https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/Models-testing.md

GLTF :: struct {
    asset: GLTF_Asset;

    _scene: s32 = -1;

    _accessors:    [..]GLTF_Accessor;
    _animations:   [..]GLTF_Animation;
    _buffers:      [..]GLTF_Buffer;
    _buffer_views: [..]GLTF_Buffer_View; @JsonName(bufferViews)
    _cameras:      [..]GLTF_Camera;
    _images:       [..]GLTF_Image;
    _materials:    [..]GLTF_Material;
    _meshes:       [..]GLTF_Mesh;
    _nodes:        [..]GLTF_Node;
    _samplers:     [..]GLTF_Sampler;
    _scenes:       [..]GLTF_Scene;
    _skins:        [..]GLTF_Skin;
    _textures:     [..]GLTF_Texture;
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

    return true, "", gltf;
}

release_gltf :: (gltf: *GLTF) {}

GLTF_Asset :: struct {}

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
