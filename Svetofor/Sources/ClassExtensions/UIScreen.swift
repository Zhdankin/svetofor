//
//  UIScreen.swift
//  Svetofor
//
//  Created by Hrebeniuk Dmytro on 02.03.2022.
//

import UIKit

extension UIScreen {
    
    var minSize: CGFloat {
        return min(bounds.width, bounds.height)
    }
    
}
