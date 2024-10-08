//
//  XunfeiAPIResponse.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/10/8.
//

import Foundation


struct XunfeiAPIResponse<T: Codable>: Codable {
    let code: Int
    let sid: String
    let message: String
    let data: T
}
