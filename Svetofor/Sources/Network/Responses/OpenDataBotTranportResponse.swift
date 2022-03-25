//
//  OpenDataBotTranportResponse.swift
//  Svetofor
//
//  Created by dhrebeniuk on 25.03.2022.
//

import Foundation

struct OpenDataBotTranportResponse: Codable {
    
    let id: Int
    let number: String
    let model: String
    let year: String
    let date: String
    let registration: String
    let capacity: Int
    let ownerHash: String
    let color: String
    let body: String
    let ownWeight: Int
    let regAddrKoatuu: Int
    
    let dep: String
        
}
