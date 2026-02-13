#import "Basic"()(
    MEMORY_DEBUGGER = true,
    TEMP_ALLOCATOR_POISON_FREED_MEMORY = true,
);
#import "Compiler";
GLTF :: #import,file "module.jai";

#run {
    set_build_options_dc({
        do_output = false,
        write_added_strings = false,
    });

    setup_formatting();

    test_lantern();
    test_mech();

    report_memory_leaks();
}

test_lantern :: () {
    converter := GLTF.create_converter();

    error, scene := GLTF.load_scene(converter, "assets/lantern/lantern.gltf");
    assert(!error, error);
    GLTF.destroy_converter(converter);
    defer GLTF.release_scene(*scene);

    // @Incomplete

    print("%\n", scene); // @ToBeDeleted
}

test_mech :: () {
    converter := GLTF.create_converter();
    defer GLTF.destroy_converter(converter);

    error, scene := GLTF.load_scene(converter, "assets/mech/mech.gltf");
    assert(!error, error);
    defer GLTF.release_scene(*scene);

    // @Incomplete
}

setup_formatting :: () {
    print_style := *context.print_style;

    print_style.default_format_struct.draw_type_name = true;
    print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 0;
    print_style.default_format_struct.use_newlines_if_long_form = true;
}
