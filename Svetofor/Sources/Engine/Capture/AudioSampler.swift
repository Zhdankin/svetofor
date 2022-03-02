//
//  AudioSampler.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 7/29/16.
//  Copyright © 2016 Dmytro Hrebeniuk. All rights reserved.
//

import AVFoundation
import CoreMedia

private let kSampleAudioBufferQueue = "com.cavap.SampleAudioBufferQueue"

public typealias AudioSamplerHandler = (_ sampleData: Data, _ timeStamp: Int64, _ samplesCount: Int64) -> Void

class AudioSampler: NSObject, Outputer, AVCaptureAudioDataOutputSampleBufferDelegate {

	fileprivate let session: AVCaptureSession
	fileprivate var audioOutput: AVCaptureAudioDataOutput!
	
	var isSoundEnabled: Bool = true

	var audioSamplerOutputHandler: AudioSamplerHandler?

	init(_ captureSession: AVCaptureSession) {
		self.session = captureSession
	}
	
	func setupOutput() {
		guard self.audioOutput == nil else { return }
		
		self.audioOutput = AVCaptureAudioDataOutput()
		let queue = DispatchQueue(label: kSampleAudioBufferQueue, attributes: []);
		self.audioOutput.setSampleBufferDelegate(self, queue: queue)
		
		if self.session.canAddOutput(self.audioOutput) {
			self.session.addOutput(self.audioOutput)
		}
	}
	
	func unSetupOutput() {
		guard self.audioOutput != nil else { return }
		
		self.session.removeOutput(self.audioOutput)
		self.audioOutput = nil
	}
	
	func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

		if let handler = self.audioSamplerOutputHandler {
			var audioBufferList: AudioBufferList = AudioBufferList()
			var blockBufferOut: CMBlockBuffer?
			var sizeOut = Int(0)
			
            guard CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: &sizeOut , bufferListOut: &audioBufferList, bufferListSize: MemoryLayout<AudioBufferList>.size, blockBufferAllocator: kCFAllocatorDefault, blockBufferMemoryAllocator: kCFAllocatorDefault, flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, blockBufferOut: &blockBufferOut)
				== noErr else { fatalError() }
			
			let audioBuffer = audioBufferList.mBuffers
			let samplesCount = Int64(CMSampleBufferGetNumSamples(sampleBuffer))
			
			let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
			
			let timeStamp = (1000 * presentationTimeStamp.value) / Int64(presentationTimeStamp.timescale)
			
			if self.isSoundEnabled {
				let data = Data(bytes: UnsafeMutableRawPointer(audioBuffer.mData!), count: Int(audioBuffer.mDataByteSize))

				handler(data, timeStamp, samplesCount)
			}
			else {
				let rawBuffer = [UInt8](repeating: 0x00, count: 2048)
                let data = Data(rawBuffer)
				handler(data, timeStamp, 1024)
			}
		}
	}
}
