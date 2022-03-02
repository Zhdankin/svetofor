//
//  ImageCropping.swift
//  PoseDetection
//
//  Created by Hrebeniuk Dmytro on 19.04.2021.
//

import Foundation
import Metal
import simd
import CoreGraphics

struct CropUniforms {
    var x: Float
    var y: Float
}

class ImageCropping {
    
    private var device: MTLDevice?
    
    private var computePipelineState: MTLComputePipelineState?

    init(device: MTLDevice?) {
        self.device = device
        let defaultLibrary = self.device?.makeDefaultLibrary()
        if let computeShader = defaultLibrary?.makeFunction(name: "cropKernel") {
            if let computePipelineState = try? self.device?.makeComputePipelineState(function: computeShader) {
                self.computePipelineState = computePipelineState
            }
        }
    }
    
    
    private var outTexture: MTLTexture?
    
    private var textureWidth: Int = 0
    private var textureHeight: Int = 0
    
    func applyCrop(inputTexture: MTLTexture, cropArea: CGRect, in commandBuffer: MTLCommandBuffer?) -> MTLTexture? {
        guard let metalDevice = self.device else {
            return nil
        }
        
        if textureWidth != Int(cropArea.width), textureHeight != Int(cropArea.height) {
            textureWidth = Int(cropArea.width)
            textureHeight = Int(cropArea.height)
            let textureCacheManager = TextureCacheManager(device: metalDevice)
            self.outTexture = textureCacheManager?.createOutputTexture(width: textureWidth, height: textureHeight, format: .rgba32Float).texure
        }
        
        guard let computePipelineState = self.computePipelineState else {
            return nil
        }
        
        guard let compute = commandBuffer?.makeComputeCommandEncoder() else {
            return nil
        }
                
        var cropUniforms = CropUniforms(x: Float(cropArea.minX), y: Float(inputTexture.height  - Int(cropArea.maxY)))
        let buffer = metalDevice.makeBuffer(bytes: &cropUniforms, length: MemoryLayout<CropUniforms>.size, options: [])
        compute.setBuffer(buffer, offset: 0, index: 0)

        compute.setComputePipelineState(computePipelineState)
        compute.setTexture(inputTexture, index: 0)
        
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
