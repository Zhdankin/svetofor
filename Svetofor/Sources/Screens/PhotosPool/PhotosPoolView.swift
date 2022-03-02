//
//  PhotosPoolView.swift
//  TongueManipulator
//
//  Created by Hrebeniuk Dmytro on 10.11.2021.
//

import Foundation
import SwiftUI

struct PhotosPoolView: View {

    @EnvironmentObject var viewModel: PhotosPoolViewModel
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.photoPoolItems , id: \.self) { item in
                    PhotoView(url: item.url)
                        .frame(width: 100.0, height: 100.0, alignment: .center)
                        .background(Color.green)
                }
            }
            
            Button("Share Collection") {
                print("!!!")
            }
        }
        .onAppear {
            viewModel.setup()
        }
    }
}
