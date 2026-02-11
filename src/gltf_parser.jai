#import "File";
#import "String";

Scene :: struct {}

load_scene :: (gltf_path: string) -> ok: bool, error: string, Scene {
    scene: Scene;

    absolute_path := gltf_path;
    if !is_absolute_path(gltf_path) {
        absolute_path = get_absolute_path(gltf_path);
    }

    ok, error, gltf := read_gltf(absolute_path);
    if !ok {
        return false, error, scene;
    }
    defer release_gltf(*gltf);

    // @Incomplete

    return true, "", scene;
}



#scope_file

#load "gltf_reader.jai";
