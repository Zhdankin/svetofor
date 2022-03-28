//
//  CarNumberDetector.swift
//  TongueManipulator
//
//  Created by Hrebeniuk Dmytro on 02.03.2022.
//

import Vision
import CoreMedia
import CoreImage

class CarNumberDetector {
    
    private var lastTextObservations: [VNRecognizedTextObservation] = [VNRecognizedTextObservation]()
    private var lastUpdatedDate: Date = Date()
    
    
    let operationQueue: OperationQueue
    init() {
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1
    }
    
    func scheduleNewCarNumber(from imageBuffer: CVPixelBuffer) {
        let pixelBuffer = imageBuffer
        
        guard self.operationQueue.operationCount == 0 else {
            return
        }
        
        guard Date().timeIntervalSince1970 - self.lastUpdatedDate.timeIntervalSince1970 > 0.05 else {
            return
        }
        
        self.operationQueue.addOperation { [weak self] in
            let request = VNRecognizeTextRequest { request, error in
                
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["uk_UA", "ru_RU"]
            request.usesLanguageCorrection = true
            request.customWords = ["АА110011", "АІ991199", "A111EE777", "BC8961II"]
                        
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
            
            try? imageRequestHandler.perform([request])
                        
            self?.lastTextObservations = request.results ?? [VNRecognizedTextObservation]()
            
            self?.lastUpdatedDate = Date()
        }
    }
    
    func requestLastAvailableCarNumbers() -> [VNRecognizedTextObservation] {
        return self.lastTextObservations
    }
}
