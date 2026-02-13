#import "Basic"()(
    MEMORY_DEBUGGER = true,
    TEMP_ALLOCATOR_POISON_FREED_MEMORY = true,
);
#import "Compiler";
#import "String";
#import "File";
GLTF :: #import,file "module.jai"(DO_SANITY_CHECKS = true);

#run {
    set_build_options_dc({
        do_output = false,
        write_added_strings = false,
    });

    setup_formatting();

    log("Jai_GLTF: Running tests");

    test_lantern();
    test_mech();
    test_mccree();

    reset_temporary_storage();

    report_memory_leaks();

    log("Jai_GLTF: All tests passed, but check above if there were any leaks!");
}

test_lantern :: () {
    converter := GLTF.create_converter();

    model_path := path_join(#filepath, "assets/lantern/lantern.gltf",, temp);

    error, scene := GLTF.load_scene(converter, model_path);
    assert(!error, error);
    GLTF.destroy_converter(converter);
    defer GLTF.release_scene(*scene);

    compare_scene_with_reference(model_path, scene);
}

test_mech :: () {
    converter := GLTF.create_converter();

    model_path := path_join(#filepath, "assets/mech/mech.gltf",, temp);

    error, scene := GLTF.load_scene(converter, model_path);
    assert(!error, error);
    GLTF.destroy_converter(converter);
    defer GLTF.release_scene(*scene);

    compare_scene_with_reference(model_path, scene);
}

test_mccree :: () {
    converter := GLTF.create_converter();

    model_path := path_join(#filepath, "assets/mccree/scene.gltf",, temp);

    error, scene := GLTF.load_scene(converter, model_path);
    assert(!error, error);
    GLTF.destroy_converter(converter);
    defer GLTF.release_scene(*scene);

    compare_scene_with_reference(model_path, scene);
}

compare_scene_with_reference :: (model_path: string, scene: GLTF.Scene) {
    expected, ok := read_entire_file(
        path_join(
            path_strip_filename(model_path,, temp),
            "reference.txt",,
            temp
        ),,
        temp,
    );
    assert(ok, "There is no reference file!");
    expected_lines := split(expected, "\n",, temp);

    actual := tprint("%", scene);
    actual_lines := split(actual, "\n",, temp);

    assert(
        expected_lines.count == actual_lines.count,
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

        assert(
            expected_line == actual_line,
            #string DONE
For model at '%':
Mismatch on line '%':
Expected: '%'
Got:      '%'
            DONE,
            model_path,
            expected_line,
            actual_line,
        );
    }
}

setup_formatting :: () {
    print_style := *context.print_style;

    print_style.default_format_struct.draw_type_name = true;
    print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 0;
    print_style.default_format_struct.use_newlines_if_long_form = true;
    print_style.default_format_array.stop_printing_after_this_many_elements = -1;
}
