/*
This file parses a `.gltf` file into a `Scene`.
The `Scene` is meant to be consumable into a rendering application.
*/

#import "Basic";
#import "File";
#import "String";

Scene :: struct {}

load_scene :: (gltf_path: string) -> ok: bool, error: string, Scene {
    scene: Scene;

    absolute_path := gltf_path;
    if !is_absolute_path(gltf_path) {
        absolute_path =, ok := get_absolute_path(gltf_path);
        if !ok {
            return false, tprint("Failed to get absotlute path for '%'", gltf_path), scene;
        }
    }

    ok, error, gltf := read_gltf(absolute_path);
    if !ok {
        return false, error, scene;
    }
    defer release_gltf(*gltf);

    if !is_supported_version(gltf) {
        return false,
            tprint("File at '%' is GLTF version '%', but only % are supported supported", absolute_path, gltf.asset.version, SUPPORTED_GLTF_VERSIONS),
            scene;
    }

    print("%\n", gltf);

    // @Incomplete

    return true, "", scene;
}



#scope_file

SUPPORTED_GLTF_VERSIONS :: string.["2.0"];

is_supported_version :: (gltf: GLTF) -> bool {
    ok := array_find(SUPPORTED_GLTF_VERSIONS, gltf.asset.version);

    return ok;
}

#load "gltf_reader.jai";
