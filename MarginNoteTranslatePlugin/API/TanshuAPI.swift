//
//  TanshuAPI.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import Foundation
import Combine

enum TanshuAPIError: Error {
    case error(String)
}

/// 探数 API
class TanshuAPI {
    public static let apiKey = "tanshu-api-key"
    public static let shared = TanshuAPI()
    
    private init() { }
    
    // 获取账户 API 的使用情况
    public func accounts(_ key: String) -> AnyPublisher<[TanshuAccountDTO], any Error> {
        let req = URLRequest(url: URL(string: "https://api.tanshuapi.com/api/account_info/v1/index?key=\(key)")!)
        return URLSession.shared.dataTaskPublisher(for: req)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap({
                $0.data
            })
            .decode(type: TanshuResponseDTO<TanshuListData<TanshuAccountDTO>>.self, decoder: JSONDecoder())
            .tryMap({
                if $0.code == 1 {
                    return $0.data.list
                } else {
                    throw TanshuAPIError.error($0.msg)
                }
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public func translate(_ keywords: String) -> AnyPublisher<String, any Error> {
        guard let key = UserDefaults.standard.string(forKey: TanshuAPI.apiKey) else {
            return Fail(outputType: String.self, failure: ApiError.keyNotFound(.tanshu))
                .eraseToAnyPublisher()
        }
        
        var req = URLRequest(url: URL(string: "https://api.tanshuapi.com/api/translate/v1/index?key=\(key)&type=deepl")!)
        req.httpMethod = "POST"
        let body: [String: String] = [
            "from": "en",
            "to": "zh",
            "keywords": keywords
        ]
        req.httpBody = try? JSONEncoder().encode(body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return URLSession.shared.dataTaskPublisher(for: req)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap({ 
                $0.data
            })
            .decode(type: TanshuResponseDTO<TanshuTranslateDTO>.self, decoder: JSONDecoder())
            .tryMap({
                if $0.code == 1 {
                    return $0.data
                } else {
                    throw TanshuAPIError.error($0.msg)
                }
            })
            .map { $0.text }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
