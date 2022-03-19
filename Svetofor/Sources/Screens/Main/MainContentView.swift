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
                
                VStack {
                    TextField("#", text: $viewModel.predictedLabel)
                        .multilineTextAlignment(.center)
                        .keyboardType(UIKit.UIKeyboardType.default)
                        .disableAutocorrection(true)
                        .padding()
                        .font(.system(size: 60))
                        .onChange(of: viewModel.predictedLabel) { newValue in
                            viewModel.performVerifyCarNumber()
                        }
                    
                    
                    Text(viewModel.alertMessage).font(.system(size: 25))
                        .frame(width: nil, height: 60.0, alignment: .center)
                }
                
                Spacer()

                GeometryReader { proxy in
                    HStack {
                        Spacer()
                        CameraViewRepresentable(renderer: viewModel, tapGestureHandler: {
                            self.viewModel.changeFocusMode(deviceLocation: $0)
                        }).frame(width: max(proxy.size.minSize - 16.0, 0.0), height: max(proxy.size.minSize * viewModel.textureHeight / viewModel.textureWidth - 16.0, 0.0), alignment: .bottomTrailing)
                        Spacer()
                    }
                }
            }.background(Color(viewModel.carNumberState.bacgroundColor))
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
