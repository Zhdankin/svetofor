//
//  MainContentViewModel.swift
//  TongueManipulator
//
//  Created by Hrebeniuk Dmytro on 10.11.2021.
//

import Foundation
import Metal
import CoreMedia
import SwiftUI



class MainContentViewModel: ObservableObject {
    
    let photosPoolViewModel = PhotosPoolViewModel()
    
    let photoCapturer: PhotoCapturer
    let webAPIClient: WebAPIClient
    private var samplesRenderer: SamplesMetalRenderer?
    private var samplesMetalImporter: SamplesMetalImporter?

    @Published var carNumberState: CarNumberVerificationState = CarNumberVerificationState.none

    @Published var alertMessage: String = ""

    @Published var isCameraAuthorized: Bool = false
    @Published var textureWidth: CGFloat = 1.0
    @Published var textureHeight: CGFloat = 1.0
        
    @Published var shouldStorePictures = false
    @Published var shouldStorePicturesLabel = "Start Store Pictures"

    @Published var predictedLabel: String = ""
    private var lastPredictedLabel: String = ""

    init(photoCapturer: PhotoCapturer = PhotoCapturer(), webAPIClient: WebAPIClient = WebAPIClient()) {
        self.photoCapturer = photoCapturer
        self.webAPIClient = webAPIClient
    }
    
    func changeShouldStorePictures() {
        self.shouldStorePictures = !self.shouldStorePictures
        self.shouldStorePicturesLabel = self.shouldStorePictures == false ? "Start Store Pictures" : "Stop Store Pictures"        
    }
    
    func setup() {
        UIApplication.shared.isIdleTimerDisabled = true
        
        let device = MTLCreateSystemDefaultDevice()
        let commandQueue = device?.makeCommandQueue(maxCommandBufferCount: 1)
        
        let samplesImporter = SamplesMetalImporter(device: device, commandQueue: commandQueue)
        samplesImporter.setup()
        self.samplesMetalImporter = samplesImporter


        samplesRenderer = SamplesMetalRenderer(device: device, commandQueue: commandQueue, samplesImporter: samplesImporter)
        samplesRenderer?.setup()
        
        self.photoCapturer.requestAccess { [weak self] isAuthorized in
            self?.isCameraAuthorized = isAuthorized
            
            if isAuthorized {
                self?.photoCapturer.cameraPosition = .back
                
                try? self?.photoCapturer.setup(videoHandler: { [weak self] (sampleBuffer, _) in
                    self?.samplesRenderer?.send(sampleBuffer: sampleBuffer)

                    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                    let width = CGFloat(imageBuffer.map { CVPixelBufferGetWidth($0) } ?? 0)
                    let height = CGFloat(imageBuffer.map { CVPixelBufferGetHeight($0) } ?? 0)
                    DispatchQueue.main.sync {
                        self?.textureWidth = width
                        self?.textureHeight = height
                    }
                })
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(2000)) {
                    self?.photoCapturer.setupContinuosAutoFocusMode(deviceLocation: .init(x: 0.5, y: 0.5))
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "PredictedTongues"), object: nil, queue: OperationQueue.main) { note in
            if let string = note.object as? String {
                if self.lastPredictedLabel != string {
                    self.lastPredictedLabel = string
                    self.predictedLabel = string
                    
                    DispatchQueue.main.async {
                        self.performVerifyCarNumber()
                    }
                }
            }
        }
    }
    
    func changeFocusMode(deviceLocation: CGPoint? = .init(x: 0.5, y: 0.5)) {
        self.photoCapturer.changeFocusMode(deviceLocation: deviceLocation)
    }
    
    func clearStoredData() {
        if let tonguesURL = FileManager.default.tonguesFolderURL {
            for fileName in ((try? FileManager.default.contentsOfDirectory(atPath: tonguesURL.path)) ?? [String]()) {
                try? FileManager.default.removeItem(at: tonguesURL.appendingPathComponent(fileName))
            }
        }
    }
    
    func performVerifyCarNumber() {
        carNumberState = .none
        var carNumber = predictedLabel.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        carNumber = carNumber.replacingOccurrences(of: "a", with: "а")
        carNumber = carNumber.replacingOccurrences(of: "b", with: "в")
        carNumber = carNumber.replacingOccurrences(of: "c", with: "с")
        carNumber = carNumber.replacingOccurrences(of: "i", with: "і")
        carNumber = carNumber.replacingOccurrences(of: "e", with: "е")
        carNumber = carNumber.replacingOccurrences(of: "o", with: "о")
        carNumber = carNumber.replacingOccurrences(of: "x", with: "х")
        carNumber = carNumber.replacingOccurrences(of: "k", with: "к")
        carNumber = carNumber.replacingOccurrences(of: "p", with: "р")
        carNumber = carNumber.replacingOccurrences(of: "n", with: "н")
        carNumber = carNumber.replacingOccurrences(of: "m", with: "м")
        carNumber = carNumber.replacingOccurrences(of: "t", with: "т")
        
        carNumber = carNumber.lowercased()
        if carNumber.count == 8 || carNumber.count == 9 || carNumber.count == 6 {
            webAPIClient.requestCheckCarNumber(carNumber: carNumber) {
                switch $0 {
                case .success(let response):
                    self.alertMessage = response.data.description
                    self.carNumberState = .badNumber
                    
                case .failure(let error):
                    switch error {
                    case .logicError(let code, let message):
                        if code == "ERR_NOT_FOUND" {
                            self.alertMessage = "Машина \(carNumber) не знайдена в базі"
                        }
                        else {
                            self.alertMessage = message
                        }
                        
                        self.carNumberState = .goodNumber
                    case .jsonError(let error):
                        self.alertMessage = error.localizedDescription
                        self.carNumberState = .error
                    case .other(let error):
                        self.alertMessage = error.localizedDescription
                        self.carNumberState = .error
                    }
                }
            }
        }
        else {
            self.carNumberState = .none
            self.alertMessage = ""
        }
    }

}

extension MainContentViewModel: CameraRenderer {
    
    func render(with renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable) {
        samplesRenderer?.render(with: renderPassDescriptor, drawable: drawable)
    }
    
    
}
