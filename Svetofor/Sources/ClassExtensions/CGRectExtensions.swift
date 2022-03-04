//
//  CGRectExtensions.swift
//  Svetofor
//
//  Created by Hrebeniuk Dmytro on 04.03.2022.
//

import Foundation
import CoreGraphics


extension CGRect {
    
    var minSize: CGFloat {
        return min(self.width, self.height)
    }
    
}
