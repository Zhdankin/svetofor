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
                    
                    Button {
                        viewModel.performVerifyCarNumber()
                    } label: {
                        Image(systemName: "paperplane")
                    }.padding()
                    
                    
                    if viewModel.isErrorShowingAlert {
                        VStack {
                            Text(viewModel.alertTitle)
                            Text(viewModel.alertMessage)
                        }
                    }
                    else if viewModel.isGoodCarShowingAlert {
                        VStack {
                            Text(viewModel.alertTitle).font(.system(size: 80))
                            Text(viewModel.alertMessage).font(.system(size: 25))
                        }
                        
                    }
                    else if viewModel.isBadCarShowingAlert {
                        VStack {
                            Text(viewModel.alertTitle).font(.system(size: 80))
                            Text(viewModel.alertMessage).foregroundColor(Color.red).font(.system(size: 25))
                        }
                        
                    }
                }
                
                Spacer()

                GeometryReader { proxy in
                    HStack {
                        Spacer()
                        CameraViewRepresentable(renderer: viewModel)
                            .frame(width: proxy.size.minSize, height: proxy.size.minSize * viewModel.textureHeight / viewModel.textureWidth, alignment: .bottomTrailing)
                        Spacer()
                    }
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
