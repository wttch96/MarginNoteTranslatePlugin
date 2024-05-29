//
//  ResponseDTO.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import Foundation


struct ResponseDTO<T>: Codable where T: Codable {
    let code: Int
    let msg: String
    let data: T
}


struct ListData<T>: Codable where T: Codable {
    let list: [T]
}

struct AccountDTO: Codable {
    let apiName: String
    let isMember: Int
    let apiId: Int
    let totalNum: Int
    let remainNum: Int
    let usedNum: Int
    
    enum CodingKeys: String, CodingKey {
        case apiName = "apiname"
        case isMember = "is_member"
        case apiId = "api_id"
        case totalNum = "total_num"
        case remainNum = "remain_num"
        case usedNum = "used_num"
    }
}


struct TranslateDTO: Codable {
    let text: String
}
