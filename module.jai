/*
API

```
load_scene :: (gltf_path: string) -> ok: bool, error: string, Scene;

release_scene :: (scene: *Scene);
```

The `Scene` itself is defined in "./src/gltf_parser.jai".
*/

#module_parameters(
    FULL_DATA: bool = false // Parse seemingly useless data from GLTF, for example the `asset` field
)();

#load "src/gltf_parser.jai";
