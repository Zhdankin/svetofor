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
    @Published var openDataBotMessage: String = ""

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
                    
                    self.actualRequest = NSUUID().uuidString
                    
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
    
    var actualRequest = NSUUID().uuidString
    
    func performVerifyCarNumber() {
        carNumberState = .none
        var carNumber = predictedLabel.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        carNumber = carNumber.replacingOccurrences(of: "a", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "b", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "c", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "i", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "e", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "o", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "x", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "k", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "p", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "n", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "m", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "t", with: "??")
        carNumber = carNumber.replacingOccurrences(of: "h", with: "??")

        carNumber = carNumber.lowercased()
        
        let currentRequest = NSUUID().uuidString
        self.actualRequest = currentRequest

        if carNumber.count == 8 || carNumber.count == 9 || carNumber.count == 6 {
            
            webAPIClient.requestCheckCarNumber(carNumber: carNumber) {
                if self.actualRequest != currentRequest {
                    return
                }
                
                switch $0 {
                case .success(let response):
                    self.alertMessage = response.data.description
                    self.carNumberState = .badNumber
                    self.openDataBotMessage = ""
                    
                    self.getOpenDataBotInfo(carNumber: carNumber, currentRequest: currentRequest)
                case .failure(let error):
                    switch error {
                    case .logicError(let code, let message):
                        if code == "ERR_NOT_FOUND" {
                            self.alertMessage = "???????????? \(carNumber) ???? ???????????????? ?? ????????"
                        }
                        else {
                            self.alertMessage = message
                        }
                        self.openDataBotMessage = ""

                        self.carNumberState = .goodNumber
                        
                        self.getOpenDataBotInfo(carNumber: carNumber, currentRequest: currentRequest)
                    case .jsonError(let error):
                        self.alertMessage = error.localizedDescription
                        self.openDataBotMessage = ""
                        self.carNumberState = .error
                    case .other(let error):
                        self.alertMessage = error.localizedDescription
                        self.openDataBotMessage = ""
                        self.carNumberState = .error
                    }
                }
            }
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                if self.actualRequest != currentRequest {
                    return
                }
                
                self.carNumberState = .none
                self.alertMessage = ""
                self.openDataBotMessage = ""
            }
        }
    }
    
    private func getOpenDataBotInfo(carNumber: String, currentRequest: String) {
        self.webAPIClient.requestOpenDatanbotCarNumberInfo(carNumber: carNumber) {
            if self.actualRequest != currentRequest {
                return
            }
            
            switch $0 {
            case .success(let openDataBotTranportResponse):
                let openDataBotMessage = "\(openDataBotTranportResponse.color) \(openDataBotTranportResponse.model) \(openDataBotTranportResponse.body))"
                self.openDataBotMessage = openDataBotMessage
            case .failure(_):
                self.openDataBotMessage = ""
            }
        }
    }

}

extension MainContentViewModel: CameraRenderer {
    
    func render(with renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable) {
        samplesRenderer?.render(with: renderPassDescriptor, drawable: drawable)
    }
    
    
}
