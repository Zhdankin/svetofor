//
//  SamplesImporter.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 12/5/17.
//  Copyright © 2017 Dmytro Hrebeniuk. All rights reserved.
//

import Metal
import CoreMedia
import Vision

protocol SamplesImporter {
	
	func setup()
	
	func fetch(imageBuffer: CVPixelBuffer, waitUntilCompleted: Bool) -> MTLTexture?
	
	func fetch(sampleBuffer: CMSampleBuffer) -> MTLTexture?
    
    func fetch() -> MTLTexture?
    
    func requestLastResultCarNumber() -> String?
    
}

class SamplesMetalImporter: SamplesImporter {

	private var device: MTLDevice? = MTLCreateSystemDefaultDevice()
	private var commandQueue: MTLCommandQueue?
	private let yuvImporter: YUVImporter

    private let faceDetector: FaceDetector
    private let carNumberDetector: CarNumberDetector
        
    var lastResultCarNumber: String? = nil
    
	init(device: MTLDevice?, commandQueue: MTLCommandQueue?) {
		self.device = device
		self.commandQueue = commandQueue
		self.yuvImporter = YUVImporterMetal(device: device)
		self.faceDetector = FaceDetector()
        self.carNumberDetector = CarNumberDetector()
	}
	
	func setup() {
		self.yuvImporter.setup()
	}
	
	func fetch(imageBuffer: CVPixelBuffer, waitUntilCompleted: Bool = false) -> MTLTexture?  {
		var resultTexture: MTLTexture? = nil
		
		if let yuvCommandBuffer = self.commandQueue?.makeCommandBuffer() {
			let texture = self.yuvImporter.performImport(imageBuffer: imageBuffer, in: yuvCommandBuffer)
			
            yuvCommandBuffer.commit()
            
            if waitUntilCompleted {
                yuvCommandBuffer.waitUntilCompleted()
            }
            
            if let commandBuffer = self.commandQueue?.makeCommandBuffer() {
                resultTexture = self.applyFilters(for: texture, imageBuffer: imageBuffer, in: commandBuffer)
                
                commandBuffer.commit()
                
                if waitUntilCompleted {
                    commandBuffer.waitUntilCompleted()
                }
            }
		}

		return resultTexture
	}
    
    func fetch()  -> MTLTexture? {
        var resultTexture: MTLTexture? = nil
        
        if let commandBuffer = self.commandQueue?.makeCommandBuffer() {
            let texture = self.yuvImporter.fetch()
            
            resultTexture = self.applyFilters(for: texture, imageBuffer: nil, in: commandBuffer)
            
            commandBuffer.commit()
            
            commandBuffer.waitUntilCompleted()
        }

        return resultTexture
    }
	
	private func applyFilters(for texture: MTLTexture?, imageBuffer: CVPixelBuffer?, in commandBuffer: MTLCommandBuffer?) -> MTLTexture? {
		var resultTexture: MTLTexture? = texture
		
        resultTexture.map() { inputTexture in
            if imageBuffer != nil {
                var summaryString = String()

                for carNumber in self.carNumberDetector.requestLastAvailableCarNumbers() {
                    for text in carNumber.topCandidates(3) {
                        let trimmedString = text.string
                            .uppercased()
                            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet.symbols)
                            .trimmingCharacters(in: CharacterSet.illegalCharacters)
                            .trimmingCharacters(in: CharacterSet.punctuationCharacters)
                            .replacingOccurrences(of: "UA", with: "")
                            .replacingOccurrences(of: "JA", with: "")
                            .replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: ".", with: "")

                        summaryString.append(contentsOf: trimmedString)
                    }
                    
                }
                
                let translitSymbols = "ABCIEOXKPNMT"
                
                let patternUA = "[\(translitSymbols)А-Я]{2}[0-9]{4}[\(translitSymbols)А-Я]{2}"
                let shortPatternUA = "[\(translitSymbols)А-Я]{2}[0-9]{3}[EBG]{1}"
                let patternRU = "[\(translitSymbols)А-Я]{1}[0-9]{3}[\(translitSymbols)А-Я]{2}[0-9]{3}"

                if let regeXpResult = summaryString.range(of: patternRU, options: .regularExpression) {
                    let text = summaryString[regeXpResult.lowerBound..<regeXpResult.upperBound]

                    lastResultCarNumber = "\(text)"
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PredictedTongues"), object: "\(text)")
                }
                else if let regeXpResult = summaryString.range(of: shortPatternUA, options: .regularExpression) {
                    let text = summaryString[regeXpResult.lowerBound..<regeXpResult.upperBound]
                    lastResultCarNumber = "\(text)"
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PredictedTongues"), object: "\(text)")
                }
                else if let regeXpResult = summaryString.range(of: patternUA, options: .regularExpression) {
                    let text = summaryString[regeXpResult.lowerBound..<regeXpResult.upperBound]
                    lastResultCarNumber = "\(text)"
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PredictedTongues"), object: "\(text)")
                }
                else {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PredictedTongues"), object: "")
                }
                
                resultTexture = inputTexture
                imageBuffer.map { self.carNumberDetector.scheduleNewCarNumber(from: $0) }
            }
        }
		
		return resultTexture
	}
	
	func fetch(sampleBuffer: CMSampleBuffer) -> MTLTexture?  {
		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return nil
		}
		
		return self.fetch(imageBuffer: imageBuffer)
	}
    
    func requestLastResultCarNumber() -> String? {
        return lastResultCarNumber
    }
	
}
