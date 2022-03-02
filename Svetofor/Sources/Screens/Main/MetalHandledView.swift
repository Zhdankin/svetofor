//
//  MetalHandledView.swift
//  StyleFilters
//
//  Created by Hrebeniuk Dmytro on 09.11.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import Metal
import MetalKit


class MetalHandledView: MTKView {
    
    let renderHandler: ((MTLRenderPassDescriptor, CAMetalDrawable) -> Void)?
    
    init(frame frameRect: CGRect, renderHandler: ((MTLRenderPassDescriptor, CAMetalDrawable) -> Void)? = nil) {
        self.renderHandler = renderHandler
        
        super.init(frame: frameRect, device: MTLCreateSystemDefaultDevice())
        
        self.delegate = self
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MetalHandledView: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let currentRenderPassDescriptor = view.currentRenderPassDescriptor,
            let currentDrawable = view.currentDrawable
            else {
                return
        }
        
        renderHandler?(currentRenderPassDescriptor, currentDrawable)
    }
}
