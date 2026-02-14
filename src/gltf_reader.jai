/*
This file reads `.gltf` files and simply parses their data into Jai types.
No manipulations are applied at all.
Everything here is meant for internal use.
*/

#scope_module

GLTF :: struct {
    asset: GLTF_Asset;

    _scene: s32 = ABSENT; @JsonName(scene)

    accessors:    [..]GLTF_Accessor;
    buffers:      [..]GLTF_Buffer;
    buffer_views: [..]GLTF_Buffer_View; @JsonName(bufferViews)
    images:       [..]GLTF_Image;
    materials:    [..]GLTF_Material;
    meshes:       [..]GLTF_Mesh;
    nodes:        [..]GLTF_Node;
    samplers:     [..]GLTF_Sampler;
    scenes:       [..]GLTF_Scene;
    textures:     [..]GLTF_Texture;
}

/*
    This procedure is called from a single place with a pool allocator.
    We don't need to free anything here.
    The pool allocator will be reset by the caller.
*/
read_gltf :: (path: string) -> error: string, GLTF {
    #if DO_SANITY_CHECKS {
        /*
            Just sanity checks.
            We call this procedure only from a single place which passes an absolute path
            and a pool allocator.
        */
        assert(
            context.allocator.proc == FP.flat_pool_allocator_proc,
            "This function can be used only with the Flat_Pool allocator.",
        );
        assert(
            is_absolute_path(path),
            "Path '%' is not an absolute path",
            path,
        );
    }

    ok, gltf := json_parse_file(path, GLTF);
    if !ok {
        return tprint("Failed to parse GLTF JSON data from %", path), gltf;
    }

    #if DO_SANITY_CHECKS {
        errors := validate(gltf, path);

        if errors {
            return errors, gltf;
        }
    }

    return "", gltf;
}

GLTF_Asset :: struct {
    version:     string;
    generator:   string;
    copyright:   string;
    min_version: string; @JsonName(minVersion)
}

GLTF_Accessor :: struct {
    _buffer_view:    s32            = ABSENT;   @JsonName(bufferView)
     byte_offset:    s32;                       @JsonName(byteOffset)
     component_type: Component_Type = .UNKNOWN; @JsonName(componentType)
     normalized:     bool;
     count:          s32;
     type:           Accessor_Type  = .UNKNOWN;
     max:            [..]float;
     min:            [..]float;
     name:           string;
     sparse:         Sparse_Incomplete;

     Sparse_Incomplete :: struct {
        // Yes, this is a required field. We are setting it to ABSENT to see if the object itself is present in the GLTF file
        _count: s32 = ABSENT; @JsonName(count)
     }

    Component_Type :: enum s32 #specified {
        UNKNOWN        :: 0;
        BYTE           :: 5120;
        UNSIGNED_BYTE  :: 5121;
        SHORT          :: 5122;
        UNSIGNED_SHORT :: 5123;
        UNSIGNED_INT   :: 5125;
        FLOAT          :: 5126;
    }

    Accessor_Type :: enum {
        UNKNOWN;
        SCALAR;
        VEC2;
        VEC3;
        VEC4;
        MAT2;
        MAT3;
        MAT4;
    }
}

GLTF_Buffer :: struct {
    uri: string;
    byte_length: s32; @JsonName(byteLength)
    name: string;
}

GLTF_Buffer_View :: struct {
     buffer:      s32;
     byte_offset: s32;               @JsonName(byteOffset)
     byte_length: s32;               @JsonName(byteLength)
    _byte_stride: s32    = ABSENT;   @JsonName(byteStride)
     target:      Target = .UNKNOWN; @JsonName(target)
     name: string;

    Target :: enum s32 #specified {
        UNKNOWN              :: 0;
        ARRAY_BUFFER         :: 34962;
        ELEMENT_ARRAY_BUFFER :: 34963;
    }
}

GLTF_Image :: struct {
     uri:         string;
    _buffer_view: s32 = ABSENT; @JsonName(bufferView)
     name:        string;
     mime_type: string; @JsonName(mimeType)
}

GLTF_Material :: struct {
    pbr_metallic_roughness: PBR_Metallic_Roughness;            @JsonName(pbrMetallicRoughness)
    normal_texture:         Normal_Texture_Info;               @JsonName(normalTexture)
    occlusion_texture:      Occlusion_Texture_Info;            @JsonName(occlusionTexture)
    emissive_texture:       Texture_Info;                      @JsonName(emissiveTexture)
    emissive_factor:        [3]float;                          @JsonName(emissiveFactor)
    alpha_mode:             Alpha_Mode              = .OPAQUE; @JsonName(alphaMode)
    alpha_cutoff:           float                   = 0.5;     @JsonName(alphaCutoff)
    double_sided:           bool;                              @JsonName(doubleSided)
    name:                   string;

    PBR_Metallic_Roughness :: struct {
        base_color_factor:          [4]float      = float.[1, 1, 1, 1]; @JsonName(baseColorFactor)
        base_color_texture:         Texture_Info;                       @JsonName(baseColorTexture)
        metallic_factor:            float         = 1;                  @JsonName(metallicFactor)
        roughness_factor:           float         = 1;                  @JsonName(roughnessFactor)
        metallic_roughness_texture: Texture_Info;                       @JsonName(metallicRoughnessTexture)
    }

    Normal_Texture_Info :: struct {
        using texture: Texture_Info;

        scale: float = 1;
    }

    Occlusion_Texture_Info :: struct {
        using texture: Texture_Info;

        strength: float = 1;
    }

    Alpha_Mode :: enum {
        UNKNOWN;
        OPAQUE;
        MASK;
        BLEND;
    }

    Texture_Info :: struct {
        _index:     s32 = ABSENT; @JsonName(index)
         tex_coord: s32;          @JsonName(texCoord)
    }
}

GLTF_Mesh :: struct {
    primitives: [..]Primitive;
    name:       string;

    Primitive :: struct {
         attributes: Attributes;
        _indices:    s32         = ABSENT;     @JsonName(indices)
        _material:   s32         = ABSENT;     @JsonName(material)
         mode:       Mode        = .TRIANGLES;

        Attributes :: struct {
            _position:   s32 = ABSENT; @JsonName(POSITION)
            _normal:     s32 = ABSENT; @JsonName(NORMAL)
            _texcoord_0: s32 = ABSENT; @JsonName(TEXCOORD_0)
        }

        Mode :: enum s32 #specified {
            POINTS         :: 0;
            LINES          :: 1;
            LINE_LOOP      :: 2;
            LINE_STRIP     :: 3;
            TRIANGLES      :: 4;
            TRIANGLE_STRIP :: 5;
            TRIANGLE_FAN   :: 6;
        }
    }
}

GLTF_Node :: struct {
     children:    [..]s32;
     // GLTF provides column-major matrix, but Jai has row-major.
     // But it doesn't matter here because Matrix4_Identity == transpose(Matrix4_Identity).
     matrix:      [16]float = #run Matrix4_Identity.floats;
    _mesh:        s32       = ABSENT;                       @JsonName(mesh)
     rotation:    [4]float  = float.[0, 0, 0, 1];
     scale:       [3]float  = float.[1, 1, 1];
     translation: [3]float;
     name:        string;
}

GLTF_Sampler :: struct {
    mag_filter: Mag_Filter = .UNKNOWN; @JsonName(magFilter)
    min_filter: Min_Filter = .UNKNOWN; @JsonName(minFilter)
    wrap_s:     Wrap_Mode  = .REPEAT;  @JsonName(wrapS)
    wrap_t:     Wrap_Mode  = .REPEAT;  @JsonName(wrapT)
    name:       string;

    Mag_Filter :: enum s32 #specified {
        UNKNOWN :: 0;
        NEAREST :: 9728;
        LINEAR  :: 9729;
    }

    Min_Filter :: enum s32 #specified {
        UNKNOWN                :: 0;
        NEAREST                :: 9728;
        LINEAR                 :: 9729;
        NEAREST_MIPMAP_NEAREST :: 9984;
        LINEAR_MIPMAP_NEAREST  :: 9985;
        NEAREST_MIPMAP_LINEAR  :: 9986;
        LINEAR_MIPMAP_LINEAR   :: 9987;
    }

    Wrap_Mode :: enum s32 #specified {
        CLAMP_TO_EDGE   :: 33071;
        MIRRORED_REPEAT :: 33648;
        REPEAT          :: 10497;
    }
}

GLTF_Scene :: struct {
    nodes: [..]s32;
    name:  string;
}

GLTF_Texture :: struct {
    _sampler: s32     = ABSENT; @JsonName(sampler)
    _source:  s32     = ABSENT; @JsonName(source)
     name:    string;
}



#scope_file

validate :: (gltf: GLTF, path: string) -> errors: string {
    push_allocator(temp);

    builder: String_Builder;

    // We support only GLTF 2.0
    SUPPORTED_GLTF_VERSIONS :: string.["2.0"];
    if !array_find(SUPPORTED_GLTF_VERSIONS, gltf.asset.version) {
        print_to_builder(
            *builder,
            "GLTF at '%' is version '%', but only % are supported\n",
            path,
            gltf.asset.version,
            SUPPORTED_GLTF_VERSIONS,
        );
    }

    // @AntiSpec
    // There should be a scene
    if gltf._scene == ABSENT {
        print_to_builder(
            *builder,
            "GLTF at '%' doesn't have a default scene\n",
            path,
        );
    }

    // @AntiSpec
    // We support only one scene
    if gltf.scenes.count != 1 {
        print_to_builder(
            *builder,
            "GLTF at '%' contains % scenes, but only 1 scene is supported",
            path,
            gltf.scenes.count,
        );
    }


    for gltf_texture: gltf.textures {
        // @AntiSpec
        // Textures should have a source in our implementation, though it's not required by the spec.
        if gltf_texture._source == ABSENT {
            print_to_builder(
                *builder,
                "GLTF at '%' has texture '%' which doesn't have a source",
                path,
                gltf_texture.name,
            );
        }
    }

    for gltf_mesh: gltf.meshes {
        for gltf_primitive: gltf_mesh.primitives {
            // @AntiSpec?
            // Every primitive should have a position
            if gltf_primitive.attributes._position == ABSENT {
                print_to_builder(
                    *builder,
                    "GLTF at '%': Primitive of mesh '%' doesn't have POSITION attribute\n",
                    path,
                    gltf_mesh.name,
                );
            }

            // Indices accessor checks
            if gltf_primitive._indices != ABSENT {
                gltf_indices_accessor := gltf.accessors[gltf_primitive._indices];

                // Indices should be scalars
                if gltf_indices_accessor.type != .SCALAR {
                    print_to_builder(
                        *builder,
                        "GLTF at '%': Primitive of mesh '%' got indices accessor who's type is '%' instead of SCALAR\n",
                        path,
                        gltf_mesh.name,
                        gltf_indices_accessor.type,
                    );
                }

                // Indices should be u16/u32
                if (
                    gltf_indices_accessor.component_type != .UNSIGNED_SHORT
                    && gltf_indices_accessor.component_type != .UNSIGNED_INT
                ) {
                    print_to_builder(
                        *builder,
                        "GLTF at '%': Primitive of mesh '%' got indices accessor who's component type is '%' instead of u16/u32\n",
                        path,
                        gltf_mesh.name,
                        gltf_indices_accessor.component_type,
                    );
                }

                // Target should be ELEMENT_ARRAY_BUFFER, but can be omitted. So we check for ARRAY_BUFFER only.
                if (
                    gltf_indices_accessor._buffer_view != ABSENT
                    && gltf.buffer_views[gltf_indices_accessor._buffer_view].target == .ARRAY_BUFFER
                ) {
                    print_to_builder(
                        *builder,
                        "GLTF at '%': Primitive of mesh '%' got buffer view into indices data that has a target of ARRAY_BUFFER\n",
                        path,
                        gltf_mesh.name,
                    );
                }

                // @AntiSpec?
                // Buffer view shouldn't have a byte stride
                if (
                    gltf_indices_accessor._buffer_view != ABSENT
                    && gltf.buffer_views[gltf_indices_accessor._buffer_view]._byte_stride != ABSENT
                ) {
                    print_to_builder(
                        *builder,
                        "GLTF at '%': Primitive of mesh '%' got buffer view into indices data that has a stride\n",
                        path,
                        gltf_mesh.name,
                    );
                }
            }
        }
    }

    return builder_to_string(*builder,, temp);
}

#import "Basic";
#import "String";
#import "Math";
#import "jaison";
FP :: #import "Flat_Pool";
