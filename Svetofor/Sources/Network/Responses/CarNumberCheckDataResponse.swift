//
//  CarNumberCheckDataResponse.swift
//  Svetofor
//
//  Created by Hrebeniuk Dmytro on 02.03.2022.
//

import Foundation


struct CarNumberCheckDetailsResponse: Codable {
    
    let name: String
    
    let description: String
    
}


struct CarNumberCheckDataResponse: Codable {
    
    let data: CarNumberCheckDetailsResponse
        
}
