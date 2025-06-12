//
//  DeepseekAPI.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2025/6/11.
//

import Combine
import Foundation
import SwiftLogMacro

struct DeepseekDTO: Encodable {
    let model: String
    let messages: [[String: String]]
    let stream: Bool
}

enum DeepseekStreamData {
    case content(String)
    case completed
}

@Log
class DeepseekAPI: NSObject, URLSessionDataDelegate {
    static let urlStr = "https://api.deepseek.com/chat/completions"
    
    private let apiKey: String
    private let prompt: String
    
    private var session: URLSession!
    private var task: URLSessionDataTask?
    
    public var streamPublisher: PassthroughSubject<DeepseekStreamData, Error> = PassthroughSubject()
    
    init(apiKey: String, prompt: String) {
        self.apiKey = apiKey
        self.prompt = prompt
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    private func createRequest() -> URLRequest {
        var req = URLRequest(url: URL(string: Self.urlStr)!)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return req
    }
    
    func completionsStream(content: String) {
        task?.cancel()
        var req = createRequest()
        
        let encoder = JSONEncoder()
        let dto = DeepseekDTO(model: "deepseek-chat", messages: [
            ["role": "system",
             "content": prompt],
            ["role": "user",
             "content": content]
        ], stream: true)
        req.httpBody = try! encoder.encode(dto)
        task = session.dataTask(with: req)
        task?.resume()
    }
    
    //
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return }
            
        // 按行分割SSE数据
        let lines = string.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            
        for line in lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6)) // 去掉"data: "前缀
                
            if jsonString == "[DONE]" {
                streamPublisher.send(.completed)
                return
            }
                
            do {
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String
                {
                    streamPublisher.send(.content(content))
                }
            } catch {
                streamPublisher.send(completion: .failure(error))
            }
        }
    }
        
    // 错误处理
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        streamPublisher.send(completion: .failure(error))
    }
}
