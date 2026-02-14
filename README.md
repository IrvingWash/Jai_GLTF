# Jai GLTF

This is a simple module for loading `.gltf` and `.glb` files into a `Scene` which is friendly for rendering applications.<br>

Currently the following features are not supported:
- Sparse accessors
- Extensions
- Cameras
- Animations and anything related to them (weights, morph targets, etc)

## Usage and API

Simply clone/copy/add as a submodule this repo into your `project_name/modules/` directory.

There are only two procederus.

```jai
create_converter :: () -> *GLTF_Converter;
destroy_converter :: (converter: *GLTF_Converter);

load_scene :: (converter: *GLTF_Converter, gltf_path: string) -> ok: bool, error: string, Scene;

release_scene :: (scene: *Scene);
```

Scene outlives the converter. The converter is needed only to call load_scene and can be immetiately released afterwards.

## Develompent

### Cloning and dependencies

This module has a single dependency as a git submodule - [jaison](https://github.com/rluba/jaison)

So to clone this repo, you need to run `git clone --recurse-submodules`

### Tools

Tools for more pleasant development can be installed by running the `install_tools.jai` routine. <br>
Currently it adds a pre-commit hook which runs tests and checks for `@``no_commit` entries in the diff.

### Structure

- `module.jai`
    Simply imports other source files.
- `src/`
    Contains all the source files with the GLTF parsing logic. Jai files in other places are used only for develompent.
- `src/gltf_reader.jai`
    This file parser JSON (`.gltf`) into Jai types without transforming any of the data.<br>
    As Jai has zero-initialization, optional GLTF fields have sentinels. All the fields that have sentinels are prefixed with `_`.
- `src/gltf_converter.jai`
    Here we convert GTF into a `Scene`.
- `src/scene.jai`
    Here we have the definition of `Scene`.
- `test.jai`
    Runs simple tests.
- `assets/`
    Contains `.gltf` files for testing.
- `modules/`
    Contains third party dependencies.

## Todo

- Add mesh merging
- Support data uris
- Support TEXCOORD_N (>0) in attributes
- Support sparse accessors (`sparse` field in `GLTF_Accessor`)
- Support animations (`animations`)
- Support `weights` in `GLTF_Mesh`
- Support `targets` in `GLTF_Mesh.Primitive`
- Support `skin` in `GLTF_Node`
- Support `weights` in `GLTF_Node`
- Support `skins`
- Support cameras `cameras`
- Support `camera` in `GLTF_Node`
