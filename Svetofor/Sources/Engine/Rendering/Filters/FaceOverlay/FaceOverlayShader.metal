//
//  FaceOverlayShader.metal
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 3/29/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

#include <metal_stdlib>
#include "../CommonUtils.h"
using namespace metal;

struct FaceOverlayUniforms {

};

kernel void faceOverlayKernel(texture2d<float, access::read> inputTexture [[ texture(0) ]],
                              texture2d<float, access::read> maskTexture [[ texture(1) ]],
						  texture2d<float, access::write> destinationTexture [[ texture(2) ]],
						  uint2 coordinate [[ thread_position_in_grid ]]) {
	
    float4 input = inputTexture.read(coordinate);
    float4 mask = maskTexture.read(coordinate/8);
    
    if (mask[3] > 0.0) {
        input = mask;
    }
    
    destinationTexture.write(input, coordinate);
}
