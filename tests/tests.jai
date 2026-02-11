GLTF :: #import,file "../module.jai";

test_test :: () {
    ok, error, gltf := GLTF.load_gltf("./tests/assets/gyro_ball/gyro_ball.gltf");
    assert(ok, "error");
    defer GLTF.release_gltf(*gltf);

    print("%\n", gltf);

    assert(GLTF.is_there(gltf._scene));
}
