//
//  FaceOverlayFilter.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 3/29/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import Metal
import Vision
import CoreMedia
import CoreVideo
import CoreGraphics

struct FaceOverlayUniforms {

}

class FaceOverlayFilter: Filter {

	var isEnabled: Bool = true

	private var device: MTLDevice?
	private var computePipelineState: MTLComputePipelineState?
	private var outTexture: MTLTexture?
    
	init(device: MTLDevice?) {
		self.device = device
		let defaultLibrary = self.device?.makeDefaultLibrary()
		if let computeShader = defaultLibrary?.makeFunction(name: "faceOverlayKernel") {
			if let computePipelineState = try? self.device?.makeComputePipelineState(function: computeShader) {
				self.computePipelineState = computePipelineState
			}
		}
	}
	
	func applyEffect(inputTexture: MTLTexture, in commandBuffer: MTLCommandBuffer?) -> MTLTexture? {
		return inputTexture
	}
    
    private func createMask(width: Int, height: Int, with face: VNFaceObservation) -> MTLTexture? {
        guard let metalDevice = self.device else {
            return nil
        }
        
        let bitmapBytesPerRow = width * 4
        let context = CGContext(data: nil, width:  width, height:  height, bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 1.0]).map() { context?.setStrokeColor($0) }
        
        context?.setLineWidth(1.0)

        if let points = face.landmarks?.faceContour?.pointsInImage(imageSize: CGSize(width: width, height: height)) {
            let path = CGMutablePath()
            
            if let point = points.first {
                path.move(to: point)
            }
            
            for point in points {
                path.addLine(to: point)
            }
            
            context?.addPath(path)
            context?.drawPath(using: CGPathDrawingMode.fill)
        }
        
        return context?.createTexture(device: metalDevice)
    }
    
    func apppyEffect(inputTexture: MTLTexture, withFace: VNFaceObservation, in commandBuffer: MTLCommandBuffer?) -> MTLTexture? {
        guard let metalDevice = self.device else {
            return inputTexture
        }
        
        guard let maskTexture = createMask(width: inputTexture.width/8, height: inputTexture.height/8, with: withFace) else {
            return inputTexture
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
        compute.setTexture(maskTexture, index: 1)
        compute.setTexture(self.outTexture, index: 2)

        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let groupsCount = MTLSize(width: inputTexture.width/threadGroupSize.width+1,
                                  height: inputTexture.height/threadGroupSize.height+1,
                                  depth: 1)
        
        compute.dispatchThreadgroups(groupsCount, threadsPerThreadgroup: threadGroupSize)
        
        compute.endEncoding()
        
        return self.outTexture
    }
    
    var isRequiredFace: Bool {
        return true
    }
}

extension FaceOverlayFilter {
	
	var name: String {
		return NSLocalizedString("Face Overlay", comment: "")
	}
	
	var iconName: String {
		return "FaceOverlay-Icon"
	}
}
