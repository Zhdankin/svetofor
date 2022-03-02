//
//  HSVShaders.metal
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 1/26/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

#include <metal_stdlib>
#include "../CommonUtils.h"
using namespace metal;

struct ColorUniforms {
    float hueFactor;
    float saturationFactor;
};

kernel void colorKernel(texture2d<float, access::read> inputTexture [[ texture(0) ]],
									texture2d<float, access::write> outputTexture [[ texture(1) ]],
									constant ColorUniforms &params [[buffer(0)]],
									uint2 coordinate [[ thread_position_in_grid ]]) {

	float4 inputColor = inputTexture.read(coordinate);
	float3 hsv = rgb2hsv(inputColor.rgb);
    
    hsv.x = clamp(hsv.x*(1.0 - params.saturationFactor) + params.hueFactor*params.saturationFactor, 0.0, 1.0);
    
	float4 newColor = clamp(float4(hsv2rgb(hsv), inputColor.a), 0.0, 1.0);
	
	outputTexture.write(newColor, coordinate);
}
