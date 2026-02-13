/*
API

```
load_scene :: (gltf_path: string) -> ok: bool, error: string, Scene;

release_scene :: (scene: *Scene);
```

The `Scene` itself is defined in "./src/gltf_parser.jai".
*/

#module_parameters(DO_SANITY_CHECKS: bool = false);

#load "src/scene.jai";
#load "src/gltf_converter.jai";



#scope_module

ABSENT: s32 : -1;
