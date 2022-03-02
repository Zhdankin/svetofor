//
//  CGContextExtensions.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 6/5/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreGraphics
import Metal

extension CGContext {
  
    func createTexture(device: MTLDevice) -> MTLTexture? {        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm, width: self.width, height: self.height, mipmapped: false)
        
        let texture = device.makeTexture(descriptor: textureDescriptor)
        
        self.data.map() {
            texture?.replace(region: MTLRegionMake2D(0, 0, self.width, self.height), mipmapLevel: 0, withBytes: $0, bytesPerRow: self.bytesPerRow)
        }
        
        return texture
    }
}
