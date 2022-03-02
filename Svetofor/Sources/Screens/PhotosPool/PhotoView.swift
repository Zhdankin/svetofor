//
//  PhotoView.swift
//  TongueManipulator
//
//  Created by Hrebeniuk Dmytro on 10.11.2021.
//

import Foundation
import UIKit
import SwiftUI


struct PhotoView: UIViewRepresentable {
    
    var url: URL?
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        let image = url.flatMap { UIImage(contentsOfFile: $0.path) }
        uiView.image = image
    }
    
}
