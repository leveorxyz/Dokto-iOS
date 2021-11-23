//
//  StateListDetails.swift
//  Dokto
//
//  Created by Rupak on 11/21/21.
//

import UIKit

struct StateListDetails: Codable {
    let message : String?
    let result : [StateListItemDetails]?
    let statusCode : Int?
    
    enum CodingKeys: String, CodingKey {
        case message = "message"
        case result = "result"
        case statusCode = "status_code"
    }
    init(from decoder: Decoder) throws {
        let values = try? decoder.container(keyedBy: CodingKeys.self)
        message = try? values?.decodeIfPresent(String.self, forKey: .message)
        result = try? values?.decodeIfPresent([StateListItemDetails].self, forKey: .result)
        statusCode = try? values?.decodeIfPresent(Int.self, forKey: .statusCode)
    }
}

struct StateListItemDetails: Codable {
    let name : String?
    let stateCode : String?
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case stateCode = "state_code"
    }
    init(from decoder: Decoder) throws {
        let values = try? decoder.container(keyedBy: CodingKeys.self)
        name = try? values?.decodeIfPresent(String.self, forKey: .name)
        stateCode = try? values?.decodeIfPresent(String.self, forKey: .stateCode)
    }
}
