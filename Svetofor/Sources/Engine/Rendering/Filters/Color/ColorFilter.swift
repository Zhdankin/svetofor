//
//  ColorFilter.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 1/26/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import Metal
import CoreMedia
import CoreVideo

struct ColorUniforms {
    var hueFactor: Float
    var saturationFactor: Float
}

class ColorFilter: Filter {
	
	var hue: Float = 0.0
    var saturation: Float = 0.0

	var isEnabled: Bool = false
	
	private var device: MTLDevice?
	private var computePipelineState: MTLComputePipelineState?
	private var outTexture: MTLTexture?

	init(device: MTLDevice?) {
		self.device = device
		let defaultLibrary = self.device?.makeDefaultLibrary()
		if let computeShader = defaultLibrary?.makeFunction(name: "colorKernel") {
			if let computePipelineState = try? self.device?.makeComputePipelineState(function: computeShader) {
				self.computePipelineState = computePipelineState
			}
		}
	}
	
	func applyEffect(inputTexture: MTLTexture, in commandBuffer: MTLCommandBuffer?) -> MTLTexture? {
		guard let metalDevice = self.device else {
			return nil
		}
		
		let textureWidth = outTexture?.width ?? 0
		let textureHeight = outTexture?.height ?? 0
		
		if textureWidth != inputTexture.width, textureHeight != inputTexture.height {

			let textureCacheManager = TextureCacheManager(device: metalDevice)
            self.outTexture = textureCacheManager?.createOutputTexture(width: inputTexture.width, height: inputTexture.height).texure
		}
		
		guard let computePipelineState = self.computePipelineState else {
			return nil
		}
		
		guard let compute = commandBuffer?.makeComputeCommandEncoder() else {
			return nil
		}
		
		compute.setComputePipelineState(computePipelineState)
		compute.setTexture(inputTexture, index: 0)
		
		var brigtnessContrastUniform = ColorUniforms(hueFactor: self.hue, saturationFactor: self.saturation)
		let buffer = device?.makeBuffer(bytes: &brigtnessContrastUniform, length: MemoryLayout<ColorUniforms>.size, options: [])
		compute.setBuffer(buffer, offset: 0, index: 0)
		
		compute.setTexture(self.outTexture, index: 1)
		
		let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
		let groupsCount = MTLSize(width: inputTexture.width/threadGroupSize.width+1,
								  height: inputTexture.height/threadGroupSize.height+1,
								  depth: 1)
		
		compute.dispatchThreadgroups(groupsCount, threadsPerThreadgroup: threadGroupSize)
		
		compute.endEncoding()
		
		return self.outTexture
	}
	
}

extension ColorFilter {

	var name: String {
		return NSLocalizedString("Color", comment: "")
	}
	
	var iconName: String {
		return "SaturationHigh-Icon"
	}
}
