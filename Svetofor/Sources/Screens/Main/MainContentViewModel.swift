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

    @Published var isShowingAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var alertTitle: String = ""

    @Published var isCameraAuthorized: Bool = false
    @Published var textureWidth: CGFloat = 1.0
    @Published var textureHeight: CGFloat = 1.0
        
    @Published var shouldStorePictures = false
    @Published var shouldStorePicturesLabel = "Start Store Pictures"

    @Published var predictedLabel: String = ""

    
    
    init(photoCapturer: PhotoCapturer = PhotoCapturer(), webAPIClient: WebAPIClient = WebAPIClient()) {
        self.photoCapturer = photoCapturer
        self.webAPIClient = webAPIClient
    }
    
    func changeShouldStorePictures() {
        self.shouldStorePictures = !self.shouldStorePictures
        self.shouldStorePicturesLabel = self.shouldStorePictures == false ? "Start Store Pictures" : "Stop Store Pictures"        
    }
    
    func setup() {
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
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(100)) {
                    self?.photoCapturer.setupAutoFocusMode(deviceLocation: .init(x: 0.5, y: 0.5))
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "PredictedTongues"), object: nil, queue: OperationQueue.main) { note in
            if let string = note.object as? String {
                self.predictedLabel = string
            }
        }
    }
    
    func clearStoredData() {
        if let tonguesURL = FileManager.default.tonguesFolderURL {
            for fileName in ((try? FileManager.default.contentsOfDirectory(atPath: tonguesURL.path)) ?? [String]()) {
                try? FileManager.default.removeItem(at: tonguesURL.appendingPathComponent(fileName))
            }
        }
    }
    
    func performVerifyCarNumber() {
        if predictedLabel.count > 0 {
            webAPIClient.requestCheckCarNumber(carNumber: predictedLabel) {
                switch $0 {
                case .success(let response):
                    print(response.data)
                case .failure(let error):
                    switch error {
                    case .logicError(let code, let message):
                        self.alertTitle = code
                        self.alertMessage = message
                    case .jsonError(let error):
                        self.alertTitle = NSLocalizedString("Error", comment: "")
                        self.alertMessage = error.localizedDescription
                    case .other(let error):
                        self.alertTitle = NSLocalizedString("Error", comment: "")
                        self.alertMessage = error.localizedDescription
                    }
                    self.isShowingAlert = true
                }
            }
        }
    }

}

extension MainContentViewModel: CameraRenderer {
    
    func render(with renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable) {
        samplesRenderer?.render(with: renderPassDescriptor, drawable: drawable)
    }
    
    
}
