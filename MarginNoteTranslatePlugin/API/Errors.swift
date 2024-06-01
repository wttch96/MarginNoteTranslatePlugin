//
//  Errors.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/31.
//

import Foundation


enum ApiError: Error {
    // api key 不存在
    case keyNotFound(APIType)
    // 服务错误
    case serviceError(APIType, String)
    // 未知错误
    case unknown(APIType, Error)
}
