//
//  OpenDataBotTranportErrorResponse.swift
//  Svetofor
//
//  Created by dhrebeniuk on 25.03.2022.
//

import Foundation

struct OpenDataBotTranportErrorResponse: Codable {
    
    let status: String
    
    let reason: String
    
    let code: Int
    
}
