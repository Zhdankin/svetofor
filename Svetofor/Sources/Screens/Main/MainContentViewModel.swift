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
    private var samplesRenderer: SamplesMetalRenderer?
    private var samplesMetalImporter: SamplesMetalImporter?

    @Published var isCameraAuthorized: Bool = false
    @Published var textureWidth: CGFloat = 1.0
    @Published var textureHeight: CGFloat = 1.0
        
    @Published var shouldStorePictures = false
    @Published var shouldStorePicturesLabel = "Start Store Pictures"

    @Published var predictedLabel: String = ""

    init(photoCapturer: PhotoCapturer = PhotoCapturer()) {
        self.photoCapturer = photoCapturer
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

}

extension MainContentViewModel: CameraRenderer {
    
    func render(with renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable) {
        samplesRenderer?.render(with: renderPassDescriptor, drawable: drawable)
    }
    
    
}
