//
//  Filter.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 1/28/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation
import Metal
import Vision

protocol Filter {
	
	var name: String { get }
	
	var iconName: String { get }

	func applyEffect(inputTexture: MTLTexture, in commandBuffer: MTLCommandBuffer?) -> MTLTexture?
	
	func apppyEffect(inputTexture: MTLTexture, withFace: VNFaceObservation, in commandBuffer: MTLCommandBuffer?, commandQueue: MTLCommandQueue?) -> MTLTexture?
	
	var isEnabled: Bool { get set }
	
	var isRequiredFace: Bool { get }
}

extension Filter {
	func apppyEffect(inputTexture: MTLTexture, withFace: VNFaceObservation, in commandBuffer: MTLCommandBuffer?, commandQueue: MTLCommandQueue?) -> MTLTexture? {
		return nil
	}

	var isRequiredFace: Bool {
		return false
	}
}
