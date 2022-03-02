//
//  CaptureSessionManager.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 7/13/16.
//  Copyright © 2016 Dmytro Hrebeniuk. All rights reserved.
//

import AVFoundation

open class CaptureSessionManager {
	
	let session: AVCaptureSession
	private var videoCapturer: VideoCapturer?
	private var videoSampler: VideoSampler?
	private var audioRecorder: AudioRecorder?
	private var audioSampler: AudioSampler?
	
	private var currentOutputer: Outputer?

	public convenience init() {
		self.init(AVCaptureSession())
	}
	
	public init(_ captureSession: AVCaptureSession) {
		self.session = captureSession
		
		self.videoCapturer = VideoCapturer(captureSession)
		self.videoSampler = VideoSampler(captureSession)

		self.audioRecorder = AudioRecorder(captureSession)
		self.audioSampler = AudioSampler(captureSession)
	}
	
	// MARK: Public

	open func requestAccess(completion: ((_ isAuthorized: Bool)-> ())? = nil) {
		AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (isAuthorized) in
			DispatchQueue.main.async {
				completion?(isAuthorized)
			}
		})
	}
	
	open func setup(videoHandler: @escaping VideoSamplerHandler, audioHandler: @escaping AudioSamplerHandler) throws -> Void {
		try self.videoCapturer?.setupCaptureSession()
		try self.audioRecorder?.setupRecordingSession()
		
		self.videoSampler?.videoSamplerOutputHandler = videoHandler
		self.audioSampler?.audioSamplerOutputHandler = audioHandler
		self.videoSampler?.setupOutput()
		self.audioSampler?.setupOutput()
		self.currentOutputer = self.videoSampler
	}
	
	open var captureSessionPreset: String = AVCaptureSession.Preset.hd1280x720.rawValue {
		didSet {
			if var config = self.videoCapturer?.configuration {
				config.captureSessionPreset = self.captureSessionPreset
				self.currentOutputer?.unSetupOutput()
				try? videoCapturer?.configure(config)
				self.currentOutputer?.setupOutput()
			}
		}
	}
	
	open var cameraPosition: AVCaptureDevice.Position = .back {
		didSet {
			self.stopCaptureSession()
			if var config = self.videoCapturer?.configuration {
				config.cameraPosition = self.cameraPosition
				if self.cameraPosition == .back {
					self.videoSampler?.isFrontCamera = false
				} else {
					self.videoSampler?.isFrontCamera = true
				}
				
				self.currentOutputer?.unSetupOutput()
				try? videoCapturer?.configure(config)
				self.currentOutputer?.setupOutput()
			}
			self.startCaptureSession()
		}
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
	
	// MARK: Properties
	
	open var isSoundEnabled: Bool {
		get {
			return self.audioSampler?.isSoundEnabled ?? false
		}
		set {
			self.audioSampler?.isSoundEnabled = newValue
		}
	}
	
	open var isMultimediaAllowed: Bool {
		get {
			let microPhoneStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
			let cameraStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
			
			return (microPhoneStatus == .authorized) && (cameraStatus == .authorized)
		}
	}
	
	open var videoOrientation: AVCaptureVideoOrientation {
		get {
			return self.videoSampler?.videoOrientation ?? .portrait
		}
		set {
			self.videoSampler?.videoOrientation = newValue
		}
	}
}
