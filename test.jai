#import "Basic"()(
    MEMORY_DEBUGGER = true,
    TEMP_ALLOCATOR_POISON_FREED_MEMORY = true,
);
#import "Compiler";

#run {
    set_build_options_dc({
        do_output = false,
        write_added_strings = false,
    });

    setup_formatting();

    test_test();

    report_memory_leaks();
}

test_test :: () {
    GLTF :: #import,file "module.jai";

    error, scene := GLTF.load_scene("assets/lantern/lantern.gltf");
    assert(!error, error);
    defer GLTF.release_scene(*scene);

    print("%\n", scene);
}

setup_formatting :: () {
    print_style := *context.print_style;

    print_style.default_format_struct.draw_type_name = true;
    print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 0;
    print_style.default_format_struct.use_newlines_if_long_form = true;
}
