//
//  VideoSampler.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 7/12/16.
//  Copyright © 2016 dmytro. All rights reserved.
//

import AVFoundation
import CoreMedia
import UIKit

let kSampleBufferQueue = "com.dmytro.iOSPhotoFilters.SampleBufferQueue"

public typealias VideoSamplerHandler = (_ sampleBuffer: CMSampleBuffer, _ timeStamp: Int64) -> Void


class VideoSampler: NSObject, Outputer, AVCaptureVideoDataOutputSampleBufferDelegate {

	private let session: AVCaptureSession
	private var videoOutput: AVCaptureVideoDataOutput!
	
	var videoSamplerOutputHandler: VideoSamplerHandler?
	var isFrontCamera: Bool?
	var videoOrientation: AVCaptureVideoOrientation = .portrait

	init(_ captureSession: AVCaptureSession) {
		self.session = captureSession
	}
	
	func setupOutput() {
		guard self.videoOutput == nil else { return }
		
		self.videoOutput = AVCaptureVideoDataOutput()
		let queue = DispatchQueue(label: kSampleBufferQueue, attributes: []);
		self.videoOutput.setSampleBufferDelegate(self, queue: queue)
		self.videoOutput.alwaysDiscardsLateVideoFrames = true
		
		self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:NSNumber(value:Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange))
		]

		if self.session.canAddOutput(self.videoOutput) {
			self.session.addOutput(self.videoOutput)
		}
		
		self.refreshOutput()
	}
	
    var resolution: CGSize? {
        let width = self.videoOutput.videoSettings["Width"] as? CGFloat
        let height = self.videoOutput.videoSettings["Height"] as? CGFloat
        return width.flatMap { width in
            height.map { CGSize(width: width, height: $0) }
        }
    }
    
	func refreshOutput() {
		for captureConnection in self.videoOutput.connections {
			captureConnection.videoOrientation = self.videoOrientation
			let mirror = isFrontCamera ?? false
			if mirror {
				captureConnection.isVideoMirrored = true
			} else {
				captureConnection.isVideoMirrored = false
			}
		}
	}
	
	func unSetupOutput() {
		guard self.videoOutput != nil else { return }

		self.session.removeOutput(self.videoOutput)
		self.videoOutput = nil
	}
	
	// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
	
	func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		if let handler = self.videoSamplerOutputHandler {
			let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
			
			let timeStamp = (1000 * presentationTimeStamp.value) / Int64(presentationTimeStamp.timescale);
						
			handler(sampleBuffer, timeStamp)
		}
	}
}
