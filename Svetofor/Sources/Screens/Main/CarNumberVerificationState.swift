//
//  CarNumberVerificationState.swift
//  Svetofor
//
//  Created by Hrebeniuk Dmytro on 05.03.2022.
//

import Foundation
import UIKit
import SwiftUI


enum CarNumberVerificationState {
    
    case none
    
    case goodNumber
    
    case badNumber
    
    case error
    
    
    var bacgroundColor: UIColor {
        switch self {
        case .none:
            return UIColor.systemBackground
        case .goodNumber:
            return UIColor.green
        case .badNumber:
            return UIColor.red
        case .error:
            return UIColor.gray
        }
    }
}
