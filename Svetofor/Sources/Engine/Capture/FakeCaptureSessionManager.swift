//
//  FakeCaptureSessionManager.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 01/09/16.
//  Copyright © 2016 Dmytro Hrebeniuk. All rights reserved.
//

import CoreImage
import AVFoundation
import UIKit

public class FakeCaptureSessionManager: CaptureSessionManager {

	fileprivate var cancelled = true
	
	fileprivate var videoHandler: VideoSamplerHandler!
	fileprivate var audioHandler: AudioSamplerHandler!
	
	open override var captureSessionPreset: String {
		get {
			return AVCaptureSession.Preset.hd1280x720.rawValue
		}
		set {
		}
	}
	
	open override var isMultimediaAllowed: Bool {
		get {
			return true
		}
	}
	
	public init() {
		super.init(AVCaptureSession())
	}
	
	override public func requestAccess(completion: ((_ isAuthorized: Bool)-> ())? = nil) {
		DispatchQueue.main.async {
			completion?(true)
		}
	}
	
	override public func setup(videoHandler: @escaping VideoSamplerHandler, audioHandler: @escaping AudioSamplerHandler) throws -> Void {
		self.videoHandler = videoHandler
		self.audioHandler = audioHandler
	}
	
	override public func startCaptureSession() -> Void {
		guard self.cancelled == true else { return }
		self.cancelled = false
		
		DispatchQueue.global().async {
			let image = UIImage(named: "city", in: Bundle(for: type(of: self)), compatibleWith: nil)
			let ciImage = CIImage(cgImage: (image?.cgImage!)!)
			
			var time: TimeInterval = 0
			
			var frameNumber = 0
			repeat {
				autoreleasepool(invoking: {
					if frameNumber < 25 {
						let videoSampleBuffer = self.createSlientVideo(ciimage: ciImage, pts: Int64(time))!
						self.videoHandler(videoSampleBuffer, Int64(time))
						self.audioHandler(Data(capacity: 2048), Int64(time), 1024)
						frameNumber += frameNumber + 1
					} else {
						time += time + 1
						frameNumber = 0
					}
				})
			}
			while(!self.cancelled)
		}
	}

	private func createSlientVideo(ciimage: CIImage, pts: Int64) -> CMSampleBuffer? {
		var sampleBuffer: CMSampleBuffer? = nil

		var pixelBuffer: CVPixelBuffer? = nil
		CVPixelBufferCreate(kCFAllocatorSystemDefault, 1280, 720, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, nil, &pixelBuffer)
		
		if let `pixelBuffer` = pixelBuffer {
			CVPixelBufferLockBaseAddress(pixelBuffer, [])
			
			let ciContext = CIContext(options: nil)
			ciContext.render(ciimage, to: pixelBuffer)
			CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
			
            var sampleTime = CMSampleTimingInfo(duration: CMTimeMake(value: 1, timescale: 25), presentationTimeStamp: CMTimeMake(value: pts, timescale: 1), decodeTimeStamp: CMTimeMake(value: pts, timescale: 1))
			
			var videoFormatDescription: CMVideoFormatDescription? = nil
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &videoFormatDescription)
			
			if let `videoFormatDescription` = videoFormatDescription {
                CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: videoFormatDescription, sampleTiming: &sampleTime, sampleBufferOut: &sampleBuffer)
			}
		}
		
		return sampleBuffer
	}
	
	override public func stopCaptureSession() {
		self.cancelled = true
	}

}
