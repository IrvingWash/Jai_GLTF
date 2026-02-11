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

    test();
}


test :: () {
    GLTF.load_gltf("./assets/gyro_ball/gyro_ball.gltf");
}
