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
                HStack {
                    CameraViewRepresentable(renderer: viewModel)
                        .frame(width: UIScreen.main.minSize, height: UIScreen.main.minSize * viewModel.textureHeight / viewModel.textureWidth, alignment: .bottomTrailing)
                        .padding()
                }
                
                Spacer()

                VStack {
                    Text(viewModel.predictedLabel)
                    
                    Button {
                        viewModel.performVerifyCarNumber()
                    } label: {
                        Image(systemName: "paperplane")
                    }.padding()
                        .alert(viewModel.alertTitle, isPresented: $viewModel.isErrorShowingAlert, actions: {
                            Button("OK", role: .cancel) { }
                        }, message: {
                            Text(viewModel.alertMessage)
                        })
                        .alert(viewModel.alertTitle, isPresented: $viewModel.isGoodCarShowingAlert, actions: {
                            Button("OK", role: .cancel) { }
                        }, message: {
                            Text(viewModel.alertMessage).foregroundColor(Color.green)
                        })
                        .alert(viewModel.alertTitle, isPresented: $viewModel.isGoodCarShowingAlert, actions: {
                            Button("OK", role: .cancel) { }
                        }, message: {
                            Text(viewModel.alertMessage).foregroundColor(Color.red)
                        })
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
