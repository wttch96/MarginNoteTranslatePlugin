//
//  ResponseDTO.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import Foundation


struct TanshuResponseDTO<T>: Codable where T: Codable {
    let code: Int
    let msg: String
    let data: T
}


struct TanshuListData<T>: Codable where T: Codable {
    let list: [T]
}

struct TanshuAccountDTO: Codable {
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


struct TanshuTranslateDTO: Codable {
    let text: String
}
