//
//  PhotoCapturer.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 1/21/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import AVFoundation

typealias PhotoSamplerHandler = (_ pixelBuffer: CVPixelBuffer) -> Void

class PhotoCapturer: NSObject, AVCapturePhotoCaptureDelegate {

	private let session: AVCaptureSession
	private var videoCapturer: VideoCapturer?
	private let videoSampler: VideoSampler?
	private var cameraOutput: AVCapturePhotoOutput!

	private var photoSamplerHandler: PhotoSamplerHandler?
	
	var videoOrientation: AVCaptureVideoOrientation = .portrait

	var videoCapturerConfiguration: VideoCapturerConfiguration = {
		var videoCapturerConfiguration = VideoCapturerConfiguration()
		videoCapturerConfiguration.captureSessionPreset = AVCaptureSession.Preset.low.rawValue
		return videoCapturerConfiguration
	}()
	
	convenience override init() {
		self.init(AVCaptureSession())
	}
	
	init(_ captureSession: AVCaptureSession) {
		self.session = captureSession
		
		self.videoCapturer = VideoCapturer(captureSession)
		self.videoSampler = VideoSampler(captureSession)
	}
	
	var cameraPosition: AVCaptureDevice.Position = .back {
		didSet {
//			guard oldValue != self.cameraPosition else {
//				return
//			}
			
			self.stopCaptureSession()
			self.videoSampler?.unSetupOutput()
			
			try? self.videoCapturer?.setupCameraPosition(self.cameraPosition)
			if self.cameraPosition == .back {
				self.videoSampler?.isFrontCamera = false
			}
			else {
				self.videoSampler?.isFrontCamera = true
			}
		
			self.videoSampler?.setupOutput()
			self.startCaptureSession()
		}
	}
	
	open func setup(videoHandler: @escaping VideoSamplerHandler) throws -> Void {
		try? self.videoCapturer?.setupCaptureSession()

		try? self.videoCapturer?.configure(self.videoCapturerConfiguration)

		self.cameraOutput = AVCapturePhotoOutput()
        self.cameraOutput.maxPhotoQualityPrioritization = .speed
		self.cameraOutput.isHighResolutionCaptureEnabled = true
		
		if (self.session.canAddOutput(self.cameraOutput)) {
			self.session.addOutput(self.cameraOutput)
		}
		
		self.videoSampler?.videoOrientation = self.videoOrientation
		self.videoSampler?.videoSamplerOutputHandler = videoHandler
		self.videoSampler?.setupOutput()

        cameraPosition = .back
        
		self.startCaptureSession()
	}

    var resolution: CGSize? {
        return self.videoSampler?.resolution
    }
    
	open func startCaptureSession() -> Void {
		if !self.session.isRunning {
			self.session.startRunning()
		}
	}
	
	open func stopCaptureSession() -> Void {
		if self.session.isRunning {
			self.session.stopRunning()
		}
	}
	
	func capturePhoto(completion: @escaping PhotoSamplerHandler) throws {
		self.photoSamplerHandler = completion

		let photoSettings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String :
			NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)])

		self.photoSamplerHandler = completion

		self.cameraOutput.capturePhoto(with: photoSettings, delegate: self)
	}
	
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		
		guard let pixelBuffer = photo.pixelBuffer else {
			return
		}
		
		self.photoSamplerHandler?(pixelBuffer)
	}
    
    func changeZoom(scale: Float) {
        self.videoCapturer?.changeZoom(scale: scale)
    }
    
    var torchMode: AVCaptureDevice.TorchMode {
        return videoCapturer?.torchMode ?? .off
    }
    
    func changeTorchMode(torchMode: AVCaptureDevice.TorchMode) {
        videoCapturer?.torchMode = torchMode
    }
    
    var hasTorchMode: Bool {
        return videoCapturer?.hasTorchMode ?? false
    }
    
    func changeFocusMode() {
        if self.videoCapturer?.focusMode == .autoFocus {
            self.videoCapturer?.focusMode = .continuousAutoFocus
        }
        else {
            self.videoCapturer?.focusMode = .autoFocus
        }
    }
    
    func setupContinuosAutoFocusMode(deviceLocation: CGPoint?) {
        self.videoCapturer?.deviceFocusLocation = deviceLocation
        self.videoCapturer?.focusMode = .continuousAutoFocus
    }
    
    func setupAutoFocusMode(deviceLocation: CGPoint?) {
        self.videoCapturer?.deviceFocusLocation = deviceLocation
        self.videoCapturer?.focusMode = .autoFocus
    }
}

extension PhotoCapturer {
	
	func requestAccess(completion: ((_ isAuthorized: Bool)-> ())? = nil) {
		AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (isAuthorized) in
			DispatchQueue.main.async {
				completion?(isAuthorized)
			}
		})
	}
	
	var isCameraAllowed: Bool {
		get {
			let cameraStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
			
			return (cameraStatus == .authorized)
		}
	}
}
