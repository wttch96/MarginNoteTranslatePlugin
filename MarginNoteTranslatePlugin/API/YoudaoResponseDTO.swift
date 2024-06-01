//
//  YoudaoResponseDTO.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/31.
//

import Foundation

struct YoudaoResponseDTO: Codable {
    // 错误返回码
    let errorCode: String
    // 源语言
    let query: String?
    // 翻译结果
    let translation: [String]?
    // 源语言和目标语言
    let l: String?
    // 词典deeplink
    let dict: [String: String]?
    // webdeeplink
    let webdict: [String: String]?
    // 翻译结果发音地址
    let tSpeakUrl: String?
    // 源语言发音地址
    let speakUrl: String?
}
