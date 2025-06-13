//
//  DeepseekAPI.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2025/6/11.
//

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
    case failure(any Error)
}

@Log("DeepseekAPI", level: .debug)
class DeepseekAPI: NSObject, URLSessionDataDelegate {
    static let urlStr = "https://api.deepseek.com/chat/completions"
    
    private let apiKey: String
    private let prompt: String
    
    private var session: URLSession!
    private var task: URLSessionDataTask?
    
    var consume: ((DeepseekStreamData) -> Void)? = nil
    
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
        req.addValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
        return req
    }
    
    func completionsStream(content: String) {
        self.task?.cancel()
        var req = self.createRequest()
        
        let encoder = JSONEncoder()
        let dto = DeepseekDTO(model: "deepseek-chat", messages: [
            ["role": "system",
             "content": prompt],
            ["role": "user",
             "content": content]
        ], stream: true)
        req.httpBody = try! encoder.encode(dto)
        self.task = self.session.dataTask(with: req)
        self.task?.resume()
        
        self.logger.debug("deepseek api 请求已发送...")
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
                self.consume?(.completed)
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
                    self.consume?(.content(content))
                }
            } catch {
                self.consume?(.failure(error))
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            if let httpResponse = task.response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if statusCode != 200 {
                    // code 出错
                    self.logger.warning("请求失败, code: \(statusCode)")
                    return
                }
            }
            self.logger.debug("Session 完成.")
            return
        }
        
        self.consume?(.failure(error))
        self.logger.debug("Session 出错: \(error.localizedDescription)")
    }
}
