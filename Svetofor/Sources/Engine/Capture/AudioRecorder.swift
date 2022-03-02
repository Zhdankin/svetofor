//
//  AudioRecorder.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 7/29/16.
//  Copyright © 2016 dmytro. All rights reserved.
//

import AVFoundation

class AudioRecorder {

	fileprivate let session: AVCaptureSession

	fileprivate var currentCaptureInput: AVCaptureDeviceInput!

	init (_ captureSession: AVCaptureSession) {
		self.session = captureSession
	}

	func setupRecordingSession() throws -> Void	{
		if self.currentCaptureInput == nil {
            
            let microPhoneStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
            if microPhoneStatus == .denied || microPhoneStatus == .restricted {
               return
            }
			let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio)
			let audioInput = try AVCaptureDeviceInput(device: videoCaptureDevice!)
			self.currentCaptureInput = audioInput
			
			self.session.addInput(audioInput)
		}
	}
}
