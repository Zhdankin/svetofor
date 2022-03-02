//
//  TextureRendererStorage.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 12/18/17.
//  Copyright © 2017 dmytro. All rights reserved.
//

import Metal

protocol TextureRendererStorage {
	
	func requestRenderedTexture() -> MTLTexture?
	
}
