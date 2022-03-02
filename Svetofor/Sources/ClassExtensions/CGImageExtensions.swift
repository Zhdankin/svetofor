//
//  MTLTextureExtensions.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 2/12/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation
import CoreGraphics
import Metal

public extension CGImage {
	
	func createTexture(device: MTLDevice) -> MTLTexture? {
		let image = self

		let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: image.bitsPerComponent, bytesPerRow: image.bytesPerRow, space: image.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
		
		context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
		
		return context?.createTexture(device: device)
	}
	
}
