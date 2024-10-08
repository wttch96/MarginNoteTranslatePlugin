//
//  XunfeiTranslateResult.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/10/8.
//

import Foundation

struct XunfeiTranslateResult: Codable {
    let result: Result
    
    struct Result: Codable {
        let from: String
        let to: String
        let trans_result: TransResult
        
        struct TransResult: Codable {
            let src: String
            let dst: String
        }
    }
}
