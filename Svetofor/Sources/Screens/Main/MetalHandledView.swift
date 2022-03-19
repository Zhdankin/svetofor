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
    
    private var tapGestureRecognizer: UITapGestureRecognizer?
    
    let tapGestureHandler: ((_ tapPoint: CGPoint) -> Void)

    init(frame frameRect: CGRect, renderHandler: ((MTLRenderPassDescriptor, CAMetalDrawable) -> Void)? = nil, tapGestureHandler: @escaping ((_ tapPoint: CGPoint) -> Void)) {
        self.renderHandler = renderHandler
        self.tapGestureHandler = tapGestureHandler
        
        super.init(frame: frameRect, device: MTLCreateSystemDefaultDevice())
        
        self.delegate = self
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.tapGestureRecognizer.map { removeGestureRecognizer($0) }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MetalHandledView.tapGestureAction(_:)))
        self.tapGestureRecognizer = tapGestureRecognizer
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tapGestureAction(_ sender: Any?) {
        let location = tapGestureRecognizer?.location(in: self)
        
        let x = (location?.x ?? 0.0) / self.bounds.width
        let y = (location?.y ?? 0.0) / self.bounds.height
        
        self.tapGestureHandler(CGPoint(x: x, y: y))
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
