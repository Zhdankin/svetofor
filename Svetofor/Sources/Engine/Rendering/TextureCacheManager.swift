//
//  TextureCacheManager.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 2/8/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import Metal
import CoreMedia
import CoreVideo

class TextureCacheManager {
	private var textureCache: CVMetalTextureCache?
	private let device: MTLDevice
	
	init?(device: MTLDevice) {
		self.device = device
	guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache) == kCVReturnSuccess
		else {
			return nil
        }
	}

    func createOutputTexture(width: Int, height: Int, format: MTLPixelFormat = .bgra8Unorm) -> (texure: MTLTexture?, pixelBuffer: CVPixelBuffer?) {
        var result: MTLTexture? = nil
        var pixelBuffer: CVPixelBuffer? = nil
        var formatIndex = UInt32(Int32(kCVPixelFormatType_32BGRA))
        
        if format == .rgba32Float {
            formatIndex = UInt32(Int32(kCVPixelFormatType_128RGBAFloat))
        }

        let pixelBufferPool = CVPixelBufferPool.createPixelBufferPool(width: Float(width), height: Float(height), format: formatIndex)
        
        _ = pixelBufferPool.flatMap() {
            CVPixelBuffer.createPixelBuffer(in: $0).flatMap() {
                pixelBuffer = $0
                result = createTexture(from: $0, format: format)
            }
        }
        
        return (texure: result, pixelBuffer: pixelBuffer)
    }
    
    func createOutputTexture(width: Int, height: Int) -> (texure: MTLTexture?, pixelBuffer: CVPixelBuffer?) {
		var result: MTLTexture? = nil
        var pixelBuffer: CVPixelBuffer? = nil
        
		let pixelBufferPool = CVPixelBufferPool.createPixelBufferPool(width: Float(width), height: Float(height))
		
		pixelBufferPool.map() {
            pixelBuffer = CVPixelBuffer.createPixelBuffer(in: $0)
            _ = pixelBuffer.map() {
				result = self.createTexture(from: $0)
			}
		}
		
		return (texure: result, pixelBuffer: pixelBuffer)
	}
	
	private func createTexture(from pixelBuffer: CVPixelBuffer, format: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
        return self.device.createTexture(from: pixelBuffer, textureCache: textureCache)
	}
}
