//
//  MTLDeviceExtensions.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 12/22/17.
//  Copyright © 2017 dmytro. All rights reserved.
//


import Metal
import CoreVideo

extension MTLDevice {
	
	func createTexture(from pixelBuffer: CVPixelBuffer, textureCache: CVMetalTextureCache? = nil, format: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
		let width = CVPixelBufferGetWidth(pixelBuffer)
		let height = CVPixelBufferGetHeight(pixelBuffer)
				
		var cvMetalTexture: CVMetalTexture?
		
		var currentTextureCache: CVMetalTextureCache? = textureCache
		
		if currentTextureCache == nil {
			guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self, nil, &currentTextureCache) == kCVReturnSuccess
				else {
					return nil
			}
		}
		
		guard let metalTextureCache = currentTextureCache else {
			return nil
		}
		
		let status = CVMetalTextureCacheCreateTextureFromImage(nil,
															   metalTextureCache, pixelBuffer, nil, format, width, height, 0, &cvMetalTexture)
		
		var texture: MTLTexture?
		if(status == kCVReturnSuccess) {
			texture = CVMetalTextureGetTexture(cvMetalTexture!)
		}
		
		return texture
	}
}
