//
//  TanshuAPI.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import Combine
import Foundation

/// 探数 API
class TanshuAPI {
    public static let apiKey = "tanshu-api-key"
    public static let shared = TanshuAPI()
    
    private init() {}
    
    // 获取账户 API 的使用情况
    public func accounts() -> AnyPublisher<[TanshuAccountDTO], any Error> {
        guard let key = UserDefaults.standard.string(forKey: TanshuAPI.apiKey) else {
            return Fail(outputType: [TanshuAccountDTO].self, failure: ApiError.keyNotFound(.tanshu))
                .eraseToAnyPublisher()
        }
        
        let req = URLRequest(url: URL(string: "https://api.tanshuapi.com/api/account_info/v1/index?key=\(key)")!)
        return URLSession.shared.dataTaskPublisher(for: req)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap {
                $0.data
            }
            .decode(type: TanshuResponseDTO<TanshuListData<TanshuAccountDTO>>.self, decoder: JSONDecoder())
            .tryMap {
                if $0.code == 1 {
                    return $0.data.list
                } else {
                    throw ApiError.serviceError(.tanshu, "\($0.code)")
                }
            }
            .receive(on: DispatchQueue.main)
            .mapError { $0 is ApiError ? $0 as! ApiError : ApiError.unknown(.tanshu, $0) }
            .eraseToAnyPublisher()
    }
    
    
    public func translate(_ keywords: String) -> AnyPublisher<String, ApiError> {
        guard let key = UserDefaults.standard.string(forKey: TanshuAPI.apiKey) else {
            return Fail(outputType: String.self, failure: ApiError.keyNotFound(.tanshu))
                .eraseToAnyPublisher()
        }
        
        var req = URLRequest(url: URL(string: "https://api.tanshuapi.com/api/translate/v1/index?key=\(key)&type=deepl")!)
        req.httpMethod = "POST"
        let body: [String: String] = [
            "from": "en",
            "to": "zh-cn",
            "keywords": keywords
        ]
        // 设置请求头
        req.httpBody = try? JSONEncoder().encode(body)
        // 设置请求体
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 发送请求
        return URLSession.shared.dataTaskPublisher(for: req)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap {
                $0.data
            }
            // 解析数据
            .decode(type: TanshuResponseDTO<TanshuTranslateDTO>.self, decoder: JSONDecoder())
            .tryMap {
                if $0.code == 1 {
                    return $0.data
                } else {
                    throw ApiError.serviceError(.tanshu, "\($0.code)")
                }
            }
            .map { $0.text }
            .receive(on: DispatchQueue.main)
            .mapError { $0 is ApiError ? $0 as! ApiError : ApiError.unknown(.tanshu, $0) }
            .eraseToAnyPublisher()
    }
}
