# Jai GLTF

## This is a work in progress!

This is a simple module for loading `.gltf` files into a `Scene` which is friendly for rendering applications.<br>
Only `.gltf` files are supported (no `.glb`).

This module is meant to be used to load models into game engines, so:
- Extensions are not supported.
- Cameras are not supported.
- Animations are not supported (but it's a top priority to bring them in).

## Usage and API

Simply clone/copy/add as a submodule this repo into your `project_name/modules/` directory.

There are only two procederus.

```jai
load_scene :: (gltf_path: string) -> ok: bool, error: string, Scene;

release_scene :: (scene: *Scene);
```

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
    As Jai has zero-initialization, optinoal GLTF fields have sentinels. All the fields that have sentinels are prefixed with `_`.
- `src/gltf_parser.jai`
    Here we convert GTF into a `Scene`.
- `test.jai`
    Runs simple tests.
- `tests/`
    Contains `.gltf` files for testing.
- `modules/`
    Contains third party dependencies.
