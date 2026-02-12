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

    containing_path := path_strip_filename(absolute_path);

    ok =, error =, loaded_gltf_buffers := load_gltf_buffers(gltf, containing_path);
    defer release_loaded_gltf_buffers(loaded_gltf_buffers);
    if !ok {
        return false, error, scene;
    }

    // =========================================================================
    // Parsing
    // =========================================================================

    // @Incomplete

    return true, "", scene;
}

release_scene :: (scene: *Scene) {
    // @Incomplete
}



#scope_file

Loaded_GLTF_Buffer :: struct {
    data:  Bytes;
    index: s32;

    Bytes :: #type,isa string;
}

SUPPORTED_GLTF_VERSIONS :: string.["2.0"];

is_supported_version :: (gltf: GLTF) -> bool {
    ok := array_find(SUPPORTED_GLTF_VERSIONS, gltf.asset.version);

    return ok;
}

load_gltf_buffers :: (gltf: GLTF, containing_path: string) -> ok: bool, error: string, [..]Loaded_GLTF_Buffer {
    buffers: [..]Loaded_GLTF_Buffer;

    for gltf_buffer: gltf.buffers {
        bytes, ok := read_entire_file(path_join(containing_path, gltf_buffer.uri,, temp));
        if !ok {
            return false, tprint("Failed to read buffer from %", gltf_buffer.uri), buffers;
        }

        array_add(
            *buffers,
            {
                data = cast(Loaded_GLTF_Buffer.Bytes, bytes),
                index = cast(s32, it_index),
            },
        );
    }

    return true, "", buffers;
}

release_loaded_gltf_buffers :: (buffers: [..]Loaded_GLTF_Buffer) {
    for buffer: buffers {
        free(buffer.data);
    }

    array_free(buffers);
}

#load "gltf_reader.jai";
