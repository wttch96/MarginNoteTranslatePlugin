//
//  YoudaoAPI.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/29.
//

import Foundation
import CryptoKit
import Combine

class YoudaoAPI {
    public static let shared = YoudaoAPI()
    
    private init() {}
    
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
    
    func translate(_ text: String, appId: String, appKey: String) -> AnyPublisher<String, any Error> {
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
            .tryMap({ $0.data })
            .tryMap({ String(data: $0, encoding: .utf8)! })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

fileprivate extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)"
            let escapedValue = "\(value)"
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

fileprivate extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove(charactersIn: "&=?")
        return characterSet
    }()
}

fileprivate extension String {
    var sha256: String {
        let digest = SHA256.hash(data: data(using: .utf8) ?? Data())

        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
}
