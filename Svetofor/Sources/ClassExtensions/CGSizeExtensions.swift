//
//  CGSizeExtensions.swift
//  Svetofor
//
//  Created by Hrebeniuk Dmytro on 04.03.2022.
//

import Foundation
import CoreGraphics


extension CGSize {
    
    var minSize: CGFloat {
        return min(self.width, self.height)
    }
    
}
