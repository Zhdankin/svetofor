//
//  FaceDetector.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 3/29/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import Vision
import CoreMedia
import CoreImage

class FaceDetector {

	private var lastFaces: [VNFaceObservation] = [VNFaceObservation]()
    private var lastUpdatedDate: Date = Date()
    
	let operationQueue: OperationQueue
	init() {
		self.operationQueue = OperationQueue()
		self.operationQueue.maxConcurrentOperationCount = 1
	}
	
    private func createResizedPixelBuffer(width: Int, height: Int, from oldPixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        var resultPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(kCFAllocatorSystemDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, nil, &resultPixelBuffer)

        guard let pixelBuffer = resultPixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])

        let pxdata = CVPixelBufferGetBaseAddress(pixelBuffer);

        let context = CGContext(data: pxdata, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

        let ciImage = CIImage(cvPixelBuffer: oldPixelBuffer)
        let ciContext = CIContext(cgContext: context!, options: [:])

        ciContext.render(ciImage, to: pixelBuffer, bounds: CGRect(x: 0, y: 0, width: width, height: height), colorSpace: CGColorSpaceCreateDeviceRGB())

        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        return resultPixelBuffer
    }
    
	func scheduleNewFace(from imageBuffer: CVPixelBuffer) {
        let pixelBuffer = imageBuffer
        
		guard self.operationQueue.operationCount == 0 else {
			return
		}
		
        guard Date().timeIntervalSince1970 - self.lastUpdatedDate.timeIntervalSince1970 > 0.05 else {
            return
        }
        
		self.operationQueue.addOperation { [weak self] in
			let request = VNDetectFaceLandmarksRequest()
			let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
			try? handler.perform([request])
			
			self?.lastFaces = request.results ?? [VNFaceObservation]()
            
            self?.lastUpdatedDate = Date()
		}
	}
	
	func requestLastAvailableFaces() -> [VNFaceObservation] {
		return self.lastFaces
	}
}
