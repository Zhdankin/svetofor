//
//  CameraViewRepresentable.swift
//  TongueManipulator
//
//  Created by Hrebeniuk Dmytro on 10.11.2021.
//

import Foundation
import SwiftUI
import Metal

struct CameraViewRepresentable: UIViewRepresentable {
    
    var renderer: CameraRenderer
    
    var tapGestureHandler: ((_ tapPoint: CGPoint) -> Void)

    func makeUIView(context: Context) -> MetalHandledView {
        let metalView = MetalHandledView.init(frame: .zero) {
            self.renderer.render(with: $0, drawable: $1)
        } tapGestureHandler: { tapGestureHandler($0) }
        
        metalView.framebufferOnly = false
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.contentScaleFactor = UIScreen.main.scale
        metalView.preferredFramesPerSecond = 30
        metalView.clipsToBounds = true
        metalView.isUserInteractionEnabled = true
        metalView.layer.borderWidth = 1.0
        metalView.layer.borderColor = UIColor.white.cgColor
        metalView.layer.cornerRadius = 5.0

        return metalView
    }

    func updateUIView(_ uiView: MetalHandledView, context: Context) {
        // TODO:
    }
    
}
