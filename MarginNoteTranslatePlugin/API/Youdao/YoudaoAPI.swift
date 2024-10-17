//
//  YoudaoAPI.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/29.
//

import Combine
import CryptoKit
import Foundation

/// 有道翻译 API
class YoudaoAPI {
    public static let shared = YoudaoAPI()
    
    private init() {}
    
    // 将输入转换为 {input} 方便签名使用
    private func toInput(_ q: String) -> String {
        let length = q.count
        
        if length > 20 {
            let startIndex = q.startIndex
            let endIndex = q.endIndex
            
            let first10 = q[startIndex..<q.index(startIndex, offsetBy: 10)]
            let last10 = q[q.index(endIndex, offsetBy: -10)..<endIndex]
            
            return "\(first10)\(length)\(last10)"
        } else {
            return q
        }
    }
        
    func asyncTranslate(_ keywords: String, appID: String, appKey: String) async throws -> String {
        
        
        return ""
    }
        
    func translate(_ text: String) -> AnyPublisher<YoudaoResponseDTO, ApiError> {
        guard let appId = UserDefaults.standard.string(forKey: .youdaoAppID),
              let appKey = UserDefaults.standard.string(forKey: .youdaoAppKey)
        else {
            return Fail(outputType: YoudaoResponseDTO.self, failure: ApiError.keyNotFound(.youdao))
                .eraseToAnyPublisher()
        }
        
        let url = URL(string: "https://openapi.youdao.com/api")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let curtime = Int(Date().timeIntervalSince1970)
        let salt = UUID().uuidString
        let sign = "\(appId)\(toInput(text))\(salt)\(curtime)\(appKey)".sha256
        
        let parameters = [
            "q": text,
            "from": "en",
            "to": "zh-CHS",
            "appKey": appId,
            "salt": salt,
            "sign": sign,
            "curtime": "\(curtime)",
            "signType": "v3"
        ]
        
        request.httpBody = parameters.percentEncoded()
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .map {
                $0.data
            }
            .decode(type: YoudaoResponseDTO.self, decoder: JSONDecoder())
            .tryMap { resp in
                if resp.errorCode == "0" {
                    return resp
                }
                
                throw ApiError.serviceError(.youdao, resp.errorCode)
            }
            .receive(on: DispatchQueue.main)
            .mapError {
                $0 is ApiError ? $0 as! ApiError : ApiError.unknown(.youdao, $0)
            }
            .eraseToAnyPublisher()
    }
}

private extension Dictionary where Key == String, Value == String {
    func percentEncoded() -> Data? {
        return map { key, value in
            return key + "=" + value
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

private extension String {
    var sha256: String {
        let digest = SHA256.hash(data: data(using: .utf8) ?? Data())

        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
}
