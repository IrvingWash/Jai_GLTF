/*
API

```
load_scene :: (gltf_path: string) -> ok: bool, error: string, Scene;

release_scene :: (scene: *Scene);
```

The `Scene` itself is defined in "./src/gltf_parser.jai".
*/

#load "src/gltf_parser.jai";
