//
//  TanshuAPI.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import Combine
import Foundation
import SwiftLogMacro

/// 探数 API
@Log("探数API", level: .debug)
class TanshuAPI {
    public static let shared = TanshuAPI()
    
    private init() {}
    
    // 获取账户 API 的使用情况
    public func accounts() -> AnyPublisher<[TanshuAccountDTO], any Error> {
        guard let key = UserDefaults.standard.string(forKey: SettingKeys.tanshuAPIKey.rawValue) else {
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
    
    /// 翻译
    ///
    /// - Parameters:
    ///  - keywords: 要翻译的文本
    ///  - apiKey: API Key
    ///  - from: 源语言
    ///  - to: 目标语言
    ///  - type: 翻译类型
    /// - Returns: 翻译结果
    /// - Throws: ApiError
    public func translate(_ keywords: String, apiKey: String, from: Language = .en, to: Language = .zh, type: TanshuAPIType? = .deepl) async throws -> String {
        let urlString = "https://api.tanshuapi.com/api/translate/v1/index?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw ApiError.url(.tanshu, urlString)
        }
        
        var req = URLRequest(url: url)
        let type = type ?? .deepl
        
        let body: [String: String] = [
            "from": from.data,
            "to": to.data,
            "keywords": keywords,
            "type": type.rawValue
        ]
        req.httpMethod = "POST"
        // 设置请求头
        req.httpBody = try? JSONEncoder().encode(body)
        // 设置请求体
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let httpResp = resp as? HTTPURLResponse {
            self.logger.debug("翻译请求结果: \(httpResp.statusCode)")
        }
        let dataStr = String(data: data, encoding: .utf8)
        
        let respData = try JSONDecoder().decode(TanshuResponseDTO<TanshuTranslateDTO>.self, from: data)
        
        self.logger.debug("响应 code: \(respData.code)")
        if respData.code != 1 {
            throw ApiError.serviceError(.tanshu, "\(respData.code)")
        }
        
        self.logger.debug("翻译结果: \(respData.data.text)")
        return respData.data.text
    }
}


fileprivate extension Language {
    var data: String {
        switch self {
        case .en:
            return "en"
        case .zh:
            return "zh-cn"
        }
    }
}
