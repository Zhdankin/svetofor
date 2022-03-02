//
//  Capturer.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 7/11/16.
//  Copyright © 2016 dmytro. All rights reserved.
//

import AVFoundation

class VideoCapturer {

	fileprivate let session: AVCaptureSession
	
	fileprivate var currentCaptureInput: AVCaptureDeviceInput?
	fileprivate(set) var configuration = VideoCapturerConfiguration()
	
	var captureSessionPreset: String = AVCaptureSession.Preset.photo.rawValue
	
	init (_ captureSession: AVCaptureSession) {
		self.session = captureSession
	}
	
	deinit {
		if self.currentCaptureInput != nil {
			self.session.removeInput(self.currentCaptureInput!)
		}
	}
	
    var focusMode: AVCaptureDevice.FocusMode = .autoFocus {
        didSet {
            currentCaptureInput.map {
                self.configureVideoCaptureDevice($0.device)
            }
        }
    }
    
	func setupCaptureSession() throws -> Void	{
		if self.currentCaptureInput == nil {
			let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            videoCaptureDevice.map { self.configureVideoCaptureDevice($0) }
	
            let videoInput = videoCaptureDevice.flatMap { try? AVCaptureDeviceInput(device: $0) }
			self.currentCaptureInput = videoInput
			
			if self.session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: self.captureSessionPreset)) {
				self.session.sessionPreset = AVCaptureSession.Preset(rawValue: captureSessionPreset)
			}
			else if self.session.canSetSessionPreset(AVCaptureSession.Preset.hd4K3840x2160) {
				self.session.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
			}
			else if self.session.canSetSessionPreset(AVCaptureSession.Preset.hd1920x1080) {
				self.session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
			}
			else if self.session.canSetSessionPreset(AVCaptureSession.Preset.hd1280x720) {
				self.session.sessionPreset = AVCaptureSession.Preset.hd1280x720
			}
			
            videoInput.map { self.session.addInput($0) }
		}
	}
    
    var deviceFocusLocation: CGPoint?

    private func configureVideoCaptureDevice(_ videoCaptureDevice: AVCaptureDevice) {
        try? videoCaptureDevice.lockForConfiguration()
        videoCaptureDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 25)
        
        if videoCaptureDevice.isFocusPointOfInterestSupported {
            self.deviceFocusLocation.map { videoCaptureDevice.focusPointOfInterest = $0 }
        }
        
        if videoCaptureDevice.isExposurePointOfInterestSupported {
            self.deviceFocusLocation.map { videoCaptureDevice.exposurePointOfInterest = $0 }
        }
        
        if focusMode == .continuousAutoFocus {
            if videoCaptureDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoCaptureDevice.focusMode = .continuousAutoFocus
            }
            
            if videoCaptureDevice.isLowLightBoostSupported {
                videoCaptureDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
            
            if videoCaptureDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoCaptureDevice.exposureMode = .continuousAutoExposure
            }

            videoCaptureDevice.isSubjectAreaChangeMonitoringEnabled = true
        }
        else {
            if videoCaptureDevice.isFocusModeSupported(.autoFocus) {
                videoCaptureDevice.focusMode = .autoFocus
            }
            if videoCaptureDevice.isLowLightBoostSupported {
                videoCaptureDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
            }
            
            if videoCaptureDevice.isExposureModeSupported(.autoExpose) {
                videoCaptureDevice.exposureMode = .autoExpose
            }
            
            videoCaptureDevice.isSubjectAreaChangeMonitoringEnabled = true
        }

        
        self.videoZoomFactor = 1.0
        
        videoCaptureDevice.unlockForConfiguration()
    }
    
	func configure(_ videoCapturingConfiguration: VideoCapturerConfiguration) throws -> Void {
		self.session.beginConfiguration()
		
        self.session.automaticallyConfiguresCaptureDeviceForWideColor = true

		try self.setupCameraPosition(videoCapturingConfiguration.cameraPosition)
		if self.session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: videoCapturingConfiguration.captureSessionPreset)) {
			self.session.sessionPreset = AVCaptureSession.Preset(rawValue: videoCapturingConfiguration.captureSessionPreset)
		}
		self.session.commitConfiguration()
	}
	
    func setupCameraPosition(_ cameraPosition: AVCaptureDevice.Position) throws -> Void {
//        guard self.currentCaptureInput?.device.position != cameraPosition else { return }
        
        if self.currentCaptureInput != nil {
            self.session.removeInput(self.currentCaptureInput!)
        }
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera], mediaType: AVMediaType.video, position: cameraPosition)
    
        var device = discoverySession.devices.filter { device -> Bool in device.position == cameraPosition }.first
    
        if device == nil {
                device = AVCaptureDevice.default(for: .video)
        }
        
        _ = try? device.map() { captureDevice in
                self.configureVideoCaptureDevice(captureDevice)
                
                let videoInput = try AVCaptureDeviceInput(device: captureDevice)
                self.currentCaptureInput = videoInput
                
                self.session.addInput(videoInput)
            }
    }
    
    private var videoZoomFactor: CGFloat = 1.0
    
    func changeZoom(scale: Float) {
        self.videoZoomFactor = self.videoZoomFactor * CGFloat(pow(scale, 0.05))

        if let videoCaptureDevice = currentCaptureInput?.device {
            do {
                try videoCaptureDevice.lockForConfiguration()
                let videoZoomFactor = max(videoCaptureDevice.minAvailableVideoZoomFactor, min(videoCaptureDevice.maxAvailableVideoZoomFactor, self.videoZoomFactor))
                     videoCaptureDevice.videoZoomFactor = videoZoomFactor
                self.videoZoomFactor = videoZoomFactor
                
                videoCaptureDevice.unlockForConfiguration()
            }
            catch {
                print("\(error.localizedDescription)")
            }
        }
    }
    
    var torchMode: AVCaptureDevice.TorchMode? {
        get {
            if let videoCaptureDevice = currentCaptureInput?.device {
                guard videoCaptureDevice.hasTorch else {
                    return nil
                }
                
                return videoCaptureDevice.torchMode
            }
            else {
                return nil
            }
        }
        set {
            if let videoCaptureDevice = currentCaptureInput?.device {
                guard videoCaptureDevice.hasTorch else {
                    return
                }
                
                do {
                    try videoCaptureDevice.lockForConfiguration()
                    videoCaptureDevice.torchMode = newValue ?? .off
                    videoCaptureDevice.unlockForConfiguration()
                }
                catch {

                }
            }
        }
    }
    
    
    var hasTorchMode: Bool {
        return currentCaptureInput?.device.hasTorch ?? false
    }
    
    
    
}
