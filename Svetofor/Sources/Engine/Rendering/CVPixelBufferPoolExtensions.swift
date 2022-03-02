//
//  CVPixelBufferPoolExtensions.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 12/22/17.
//  Copyright © 2017 dmytro. All rights reserved.
//

import Metal
import CoreVideo

extension CVPixelBufferPool {
	
    class func createPixelBufferPool(width: Float, height: Float, format: UInt32 = UInt32(Int32(kCVPixelFormatType_32BGRA))) -> CVPixelBufferPool? {
        let poolAttributes = NSMutableDictionary()
        poolAttributes[kCVPixelBufferPoolMinimumBufferCountKey] = NSNumber(value: Int32(6))
        let pixelBufferAttributes = NSMutableDictionary()
        pixelBufferAttributes[kCVPixelBufferWidthKey] = NSNumber(value: Int32(width))
        pixelBufferAttributes[kCVPixelBufferHeightKey] = NSNumber(value: Int32(height))
        pixelBufferAttributes[kCVPixelBufferPixelFormatTypeKey] = NSNumber(value: format)
                
        let ioSurfaceProperties = NSMutableDictionary()
        ioSurfaceProperties["IOSurfaceIsGlobal"] = NSNumber(value: true)
        ioSurfaceProperties["IOSurfacePurgeWhenNotInUse"] = NSNumber(value: true)
        pixelBufferAttributes[kCVPixelBufferIOSurfacePropertiesKey] = ioSurfaceProperties
        pixelBufferAttributes["CacheMode"] = [1024, 0, 256, 512, 768, 1280]
        
        var pixelBufferPool: CVPixelBufferPool? = nil
        CVPixelBufferPoolCreate(nil, poolAttributes, pixelBufferAttributes, &pixelBufferPool)
        
        return pixelBufferPool
    }
}
