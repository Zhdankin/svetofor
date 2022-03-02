//
//  ImageCropping.metal
//  PoseDetection
//
//  Created by Hrebeniuk Dmytro on 19.04.2021.
//

#include <metal_stdlib>
using namespace metal;

struct CropUniforms {
    float x;
    float y;
};

kernel void cropKernel(texture2d<float, access::read> inputTexture [[ texture(0) ]],
                                    texture2d<float, access::write> outputTexture [[ texture(1) ]],
                                    constant CropUniforms &params [[buffer(0)]],
                                    uint2 coordinate [[ thread_position_in_grid ]]) {
    
    uint2 offsetCorrdinate = uint2(float(coordinate.x) + params.x, float(coordinate.y) + params.y);
        
    float4 inputColor = inputTexture.read(offsetCorrdinate);
    
    outputTexture.write(inputColor, coordinate);
}
