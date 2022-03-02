//
//  TongueManipulatorApp.swift
//  TongueManipulator
//
//  Created by Hrebeniuk Dmytro on 10.11.2021.
//

import SwiftUI

@main
struct TongueManipulatorApp: App {
    var body: some Scene {
        WindowGroup {
            MainContentView().environmentObject(MainContentViewModel())
        }
    }
}
