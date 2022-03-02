//
//  FileManagerExtensions.swift
//  TongueManipulator
//
//  Created by Hrebeniuk Dmytro on 10.11.2021.
//

import Foundation


extension FileManager {
    
    var tonguesFolderURL: URL? {
        FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).first?.appendingPathComponent("tongues")
    }
    
    
}
