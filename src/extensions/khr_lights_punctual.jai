#scope_module

KHR_Lights_Punctual :: union {
    lights: [..]KHR_Light;
    _light:  s32            = -1; @JsonName(light)
};

KHR_Light :: struct {
    name:      string;

    type: Light_Type = .UNKNOWN;

    color:     [3]float    = float.[1, 1, 1];
    intensity: float       = 1;
    range:     float       = FLOAT32_INFINITY;

    spot: Spot;

    Spot :: struct {
        inner_cone_angle: float;          @JsonName(innerConeAngle)
        outer_cone_angle: float = PI / 4; @JsonName(outerConeAngle)
    }

    Light_Type :: enum {
        UNKNOWN;
        directional;
        point;
        spot;
    }
}



#scope_file

#import "Math";
