//
//  VideoCapturerConfiguration.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 7/11/16.
//  Copyright © 2016 dmytro. All rights reserved.
//

import AVFoundation

struct VideoCapturerConfiguration {
	
	var cameraPosition: AVCaptureDevice.Position = .back
	var captureSessionPreset: String = AVCaptureSession.Preset.hd4K3840x2160.rawValue
}
