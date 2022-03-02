//
//  UIImageExtensions.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 1/24/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreVideo


extension UIImage {

	func rotated(to angle: CGFloat = CGFloat.pi/2.0) -> UIImage? {
		let size = CGSize(width: self.size.height, height: self.size.width)
		
		UIGraphicsBeginImageContext(size)
		
		let context = UIGraphicsGetCurrentContext()
		context?.rotate(by: angle)
		context?.translateBy(x: 0.0, y: -self.size.height)
		
		self.draw(in: CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height))
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image
	}
	
	func leftToRightRotated() -> UIImage? {
		let size = CGSize(width: self.size.height, height: self.size.width)

		UIGraphicsBeginImageContext(size)

		let context = UIGraphicsGetCurrentContext()
		context?.scaleBy(x: 1.0, y: -1.0)
		context?.translateBy(x: 0.0, y: -self.size.height)
		context?.rotate(by: -CGFloat.pi/2.0)
		context?.translateBy(x: -self.size.height, y: 0.0)
		
		self.draw(in: CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height))
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image
	}
	
	func thumb(with size: CGSize) -> UIImage? {
		UIGraphicsBeginImageContext(size)
		
		self.draw(in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image
	}
    
    
    func pixelBuffer(bufferSize: CGSize? = nil) -> CVPixelBuffer? {

        let width = Int(bufferSize?.width ?? self.size.width)
        let height = Int(bufferSize?.height ?? self.size.height)

        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }

        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }
	

}
