//
//  VerifyCarNumberError.swift
//  Svetofor
//
//  Created by Hrebeniuk Dmytro on 02.03.2022.
//

import Foundation


enum VerifyCarNumberError: Error {
    
    case logicError(String, String)
    
    case jsonError(Error)
    
    case other(Error)
    
    
}
