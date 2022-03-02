//
//  FaceAdjustShader.metal
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 7/1/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct FaceAdjustUniforms {
    float lipsAdjustValue;
    float scaleX;
    float scaleY;
};

kernel void faceAdjustKernel(texture2d<float, access::read> inputTexture [[ texture(0) ]],
                             texture2d<float, access::read> maskTexture [[ texture(1) ]],
                             texture2d<float, access::read> lipsTexture [[ texture(2) ]],
                              texture2d<float, access::write> destinationTexture [[ texture(3) ]],
                              constant FaceAdjustUniforms &params [[buffer(0)]],
                              uint2 coordinate [[ thread_position_in_grid ]]) {
    
    uint2 scaledCoordinate = uint2(float(coordinate.x)*params.scaleX, float(coordinate.y)*params.scaleY);

    float4 input = inputTexture.read(scaledCoordinate);
    float4 mask = maskTexture.read(scaledCoordinate);
    
    float4 lips = lipsTexture.read(scaledCoordinate);
    

    if (mask[3] > 0.0) {
        input = mask;
    }
    
    destinationTexture.write(lips, coordinate);
}

