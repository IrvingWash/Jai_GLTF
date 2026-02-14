// Pass `--create-refs` to generate new scene "expected" results for models

#import "Basic"()(
    MEMORY_DEBUGGER = true,
    TEMP_ALLOCATOR_POISON_FREED_MEMORY = true,
);
#import "Compiler";
#import "String";
#import "File";
#import "Print_Color";
#import "xxHash";
GLTF :: #import,file "module.jai"(DO_SANITY_CHECKS = true);

HASH_SEED :: 1;

create_refs: bool = false;

#run {
    set_build_options_dc({
        do_output = false,
        write_added_strings = false,
    });

    cli_arguments := get_build_options().compile_time_command_line;
    for argument: cli_arguments {
        if argument == {
            case "--create-refs";
                create_refs = true;
            case;
                assert(false, "Unknown argument '%'", argument);
        }
    }

    setup_formatting();

    print_color("Jai_GLTF: Running tests\n", color = .YELLOW, style = .BOLD);

    test_mech_glb();
    test_mech();
    test_glb_lantern();
    test_lantern();
    test_mccree();

    print_color("Jai_GLTF: All tests finished\n", color = .YELLOW, style = .BOLD);

    reset_temporary_storage();

    report_memory_leaks();
}

test_lantern :: () {
    converter := GLTF.create_converter();

    model_path := path_join(#filepath, "assets/lantern/lantern.gltf",, temp);

    error, scene := GLTF.load_scene(converter, model_path);
    erase_image_data(*scene);
    GLTF.destroy_converter(converter);

    if !expect(error, "", error) {
        return;
    }

    defer GLTF.release_scene(*scene);

    if create_refs {
        create_reference(model_path, scene);
    }

    compare_scene_with_reference(model_path, scene);
}

test_glb_lantern :: () {
    converter := GLTF.create_converter();

    model_path := path_join(#filepath, "assets/lantern_glb/lantern.glb",, temp);

    error, scene := GLTF.load_scene(converter, model_path);
    erase_image_data(*scene);
    GLTF.destroy_converter(converter);

    if !expect(error, "", error) {
        return;
    }

    defer GLTF.release_scene(*scene);

    if create_refs {
        create_reference(model_path, scene);
    }

    compare_scene_with_reference(model_path, scene);
}

test_mech :: () {
    converter := GLTF.create_converter();

    model_path := path_join(#filepath, "assets/mech/mech.gltf",, temp);

    error, scene := GLTF.load_scene(converter, model_path);
    erase_image_data(*scene);
    GLTF.destroy_converter(converter);

    if !expect(error, "", error) {
        return;
    }

    defer GLTF.release_scene(*scene);

    if create_refs {
        create_reference(model_path, scene);
    }

    compare_scene_with_reference(model_path, scene);
}

test_mech_glb :: () {
    converter := GLTF.create_converter();

    model_path := path_join(#filepath, "assets/mech_glb/mech.glb",, temp);

    error, scene := GLTF.load_scene(converter, model_path);
    erase_image_data(*scene);
    GLTF.destroy_converter(converter);

    if !expect(error, "", error) {
        return;
    }

    defer GLTF.release_scene(*scene);

    if create_refs {
        create_reference(model_path, scene);
    }

    compare_scene_with_reference(model_path, scene);
}

test_mccree :: () {
    converter := GLTF.create_converter();

    model_path := path_join(#filepath, "assets/mccree/scene.gltf",, temp);

    error, scene := GLTF.load_scene(converter, model_path);
    erase_image_data(*scene);
    GLTF.destroy_converter(converter);

    if !expect(error, "", error) {
        return;
    }

    defer GLTF.release_scene(*scene);

    if create_refs {
        create_reference(model_path, scene);
    }

    compare_scene_with_reference(model_path, scene);
}

compare_scene_with_reference :: (model_path: string, scene: GLTF.Scene) -> ok: bool {
    root_dir := path_strip_filename(model_path,, temp);

    actual := tprint("%", scene,, temp);

    actual_hashed := native_XXH64(actual.data, xx actual.count, HASH_SEED);

    expected_hashed_string, ok := read_entire_file(
        path_join(
            root_dir,
            "hashed_reference.txt",,
            temp
        ),,
        temp,
    );
    if !expect(ok, true, "There is no hashed reference file!\n") {
        return false;
    }

    expected_hashed:, ok=, remainder := string_to_int(expected_hashed_string, T = u64);
    assert(
        ok && !remainder,
        "Failed to compare hashes for '%', because the stored hash couldn't be parsed into a number",
        model_path,
    );

    if expect(actual_hashed, expected_hashed, "Hashes didn't match for '%'", model_path) {
        return true;
    }

    // =========================================================================
    // Generate readable errors
    // =========================================================================

    expected:, ok = read_entire_file(
        path_join(
            root_dir,
            "reference.txt",,
            temp
        ),,
        temp,
    );

    if !expect(ok, true, "There is no reference file!\n") {
        return false;
    }

    expected_lines := split(expected, "\n",, temp);

    actual_lines := split(actual, "\n",, temp);

    expect(
        expected_lines.count,
        actual_lines.count,
        #string DONE
For model at '%':
Expected % lines got %
        DONE,
        model_path,
        expected_lines.count,
        actual_lines.count,
    );

    for expected_line: expected_lines {
        actual_line := actual_lines[it_index];

        expect(
            expected_line,
            actual_line,
            #string DONE
For model at '%':
Mismatch on line '%':
Expected: '%'
Got:      '%'
            DONE,
            model_path,
            it_index + 1,
            expected_line,
            actual_line,
        );
    }

    return false;
}

expect :: (actual: $T, expected: T, format_string: string, args: ..Any) -> bool {
    if actual == expected {
        return true;
    }

    print_color(format_string, ..args, color = .RED, to_standard_error = true);

    return false;
}

create_reference :: (path: string, scene: GLTF.Scene) {
    serialized_scene := tprint("%", scene);

    root_dir := path_strip_filename(path,, temp);

    write_entire_file(
        path_join(
            root_dir,
            "hashed_reference.txt",,
            temp,
        ),
        tprint(
            "%",
            native_XXH64(serialized_scene.data, xx serialized_scene.count, HASH_SEED,, temp)
        ),
    );

    write_entire_file(
        path_join(
            root_dir,
            "reference.txt",,
            temp
        ),
        serialized_scene,
    );
}

// Erasing this stuff so the printing is not too huge.
erase_image_data :: (scene: *GLTF.Scene) {
    for *material: scene.materials {
        free(material.pbr_metallic_roughness.base_color_texture.image_data);
        free(material.pbr_metallic_roughness.metallic_roughness_texture.image_data);
        free(material.normal_texture.texture.image_data);
        free(material.occlusion_texture.texture.image_data);
        free(material.emissive_texture.texture.image_data);

        material.pbr_metallic_roughness.base_color_texture.image_data = {};
        material.pbr_metallic_roughness.metallic_roughness_texture.image_data = {};
        material.normal_texture.texture.image_data = {};
        material.occlusion_texture.texture.image_data = {};
        material.emissive_texture.texture.image_data = {};
    }
}

setup_formatting :: () {
    print_style := *context.print_style;

    print_style.default_format_struct.draw_type_name = true;
    print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 0;
    print_style.default_format_struct.use_newlines_if_long_form = true;
    print_style.default_format_struct.separator_between_name_and_value = "=";
    print_style.default_format_struct.short_form_separator_between_fields = ",";
    print_style.default_format_struct.long_form_separator_between_fields  = ";";
    print_style.default_format_struct.indentation_width = 1;

    print_style.default_format_array.stop_printing_after_this_many_elements = -1;
    print_style.default_format_array.separator = ",";
}
