//
//  CameraRenderer.swift
//  TongueManipulator
//
//  Created by Hrebeniuk Dmytro on 10.11.2021.
//

import Foundation
import Metal

protocol CameraRenderer {
    
    func render(with renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable)
    
}
