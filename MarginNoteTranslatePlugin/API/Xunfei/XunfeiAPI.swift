//
//  XunfeiAPI.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/10/8.
//

import CryptoKit
import Foundation
import SwiftLogMacro

/// 讯飞 API 密钥
struct XunfeiAPISecret {
    /// 讯飞 APP ID
    let appID: String
    /// 讯飞 API 密钥
    let secret: String
    /// 讯飞 API Key
    let key: String
}

@Log("讯飞翻译", level: .debug)
class XunfeiAPI {
    public static let shared = XunfeiAPI()
    
    /// 日期格式化器, RFC1123
    private let dateFormatter: DateFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    }
    
    func translate(_ keywords: String, secret: XunfeiAPISecret, from: Language = .en, to: Language = .zh) async throws -> String {
        guard let keywords = keywords.data(using: .utf8)?.base64EncodedString() else {
            throw ApiError.serviceError(.xunfei, "keyword 编码失败")
        }
        // 请求 body
        guard let body = try? JSONEncoder().encode([
            "common": [
                "app_id": secret.appID
            ],
            "business": [
                "from": from.text,
                "to": to.text
            ],
            "data": [
                "text": keywords
            ]
        ]) else {
            throw ApiError.serviceError(.xunfei, "body json 失败!")
        }
        
        let httpProto = "HTTP/1.1"
        let requestUri = "/v2/its"
        let host = "itrans.xfyun.cn"
        let method = "POST"
        let digest = "SHA-256=\(Data(SHA256.hash(data: body)).base64EncodedString())"
        let dateStr = dateFormatter.string(from: Date())
        
        let signedStr = signaure(
            secret: secret.secret,
            host: host, date: dateStr,
            httpMethod: method, requestUri: requestUri, httpProto: httpProto,
            digest: digest)
        
        let url = URL(string: "https://\(host)\(requestUri)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        request.setValue("application/json,version=1.0", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue(dateStr, forHTTPHeaderField: "Date")
        request.setValue(digest, forHTTPHeaderField: "Digest")
        request.setValue("api_key=\"\(secret.key)\", algorithm=\"hmac-sha256\", headers=\"host date request-line digest\", signature=\"\(signedStr)\"", forHTTPHeaderField: "Authorization")
        
        request.httpBody = body
        
        let (data, resp) = try await URLSession.shared.data(for: request)
        let httpResp = resp as! HTTPURLResponse
        guard httpResp.statusCode == 200 else {
            throw ApiError.serviceError(.xunfei, "HTTP Status Code: \(httpResp.statusCode)")
        }
        
        guard let result = try? JSONDecoder().decode(XunfeiAPIResponse<XunfeiTranslateResult>.self, from: data) else {
            throw ApiError.serviceError(.xunfei, "解析结果失败")
        }
        if result.code != 0 {
            throw ApiError.serviceError(.xunfei, "错误代码: \(result.code), 错误信息: \(result.message)")
        }
        
        return result.data.result.trans_result.dst
    }
    
    /// 计算签名
    /// - Parameters:
    ///  - secret: API 密钥
    ///  - host: Host
    ///  - date: 日期
    ///  - httpMethod: HTTP 方法
    ///  - requestUri: 请求 URI
    ///  - httpProto: HTTP 协议
    ///  - digest: 请求 body 的 SHA256 摘要
    private func signaure(
        secret: String, host: String, date: String,
        httpMethod: String, requestUri: String, httpProto: String,
        digest: String) -> String
    {
        let signStr = """
        host: \(host)
        date: \(date)
        \(httpMethod) \(requestUri) \(httpProto)
        digest: \(digest)
        """
        
        // Convert key and message to Data
        let keyData = SymmetricKey(data: Data(secret.utf8))
        let messageData = Data(signStr.utf8)

        // Compute HMAC using SHA-256
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: keyData)

        // Convert HMAC result to Data
        let hmacData = Data(hmac)

        // Encode HMAC to Base64 (optional)
        let base64HmacString = hmacData.base64EncodedString()
        
        return base64HmacString
    }
}

private extension Language {
    var text: String {
        switch self {
        case .en:
            return "en"
        case .zh:
            return "cn"
        }
    }
}
