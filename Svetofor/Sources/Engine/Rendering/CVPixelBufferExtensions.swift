//
//  CVPixelBufferExtensions.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 12/22/17.
//  Copyright © 2017 dmytro. All rights reserved.
//

import Metal
import CoreVideo

extension CVPixelBuffer {
	
	class func createPixelBuffer(in pool: CVPixelBufferPool) -> CVPixelBuffer? {
		
		var pixelBuffer: CVPixelBuffer? = nil
		
		CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
		if pixelBuffer != nil {
			CVBufferSetAttachment(pixelBuffer!, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, .shouldPropagate)
			CVBufferSetAttachment(pixelBuffer!, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, .shouldPropagate)
			CVBufferSetAttachment(pixelBuffer!, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, .shouldPropagate)
		}
		
		return pixelBuffer
	}
}
