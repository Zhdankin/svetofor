//
//  MainContentView.swift
//  TongueManipulator
//
//  Created by Hrebeniuk Dmytro on 10.11.2021.
//

import SwiftUI

struct MainContentView: View {
    
    @EnvironmentObject var viewModel: MainContentViewModel

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text(viewModel.predictedLabel)

                HStack {
                    CameraViewRepresentable(renderer: viewModel)
                        .frame(width: 300.0, height: 300.0 * viewModel.textureHeight / viewModel.textureWidth, alignment: .bottomTrailing)
                        .padding()
                    
                    Spacer()
                    
                    
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarTitle("")
        .onAppear() {
            viewModel.setup()
        }
    }
}

struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
    }
}
