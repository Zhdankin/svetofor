//
//  PhotosPoolViewModel.swift
//  TongueManipulator
//
//  Created by Hrebeniuk Dmytro on 10.11.2021.
//

import Foundation


class PhotosPoolViewModel: ObservableObject {
    
    struct PhotoPoolItemViewModel: Hashable {
        
        let url: URL
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(url)
        }
        
    }

    @Published var photoPoolItems: [PhotoPoolItemViewModel] = [PhotoPoolItemViewModel]()

    func setup() {
        var items = [PhotoPoolItemViewModel]()
        
        if let tonguesURL = FileManager.default.tonguesFolderURL {
            for fileName in ((try? FileManager.default.contentsOfDirectory(atPath: tonguesURL.path)) ?? [String]()) {
                let url = tonguesURL.appendingPathComponent(fileName)
                let item = PhotoPoolItemViewModel.init(url: url)
                items.append(item)
            }
        }
        
        self.photoPoolItems = items
    }
    
}
