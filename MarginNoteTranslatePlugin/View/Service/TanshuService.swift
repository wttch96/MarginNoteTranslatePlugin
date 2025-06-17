//
//  TanshuService.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2025/6/13.
//

import Combine
import Foundation
import SwiftLogMacro

@Log("探数翻译", level: .debug)
class TanshuService: TranslateService {
    var result: PassthroughSubject<(Bool, String), ApiError> = PassthroughSubject()
    
    init() {}
    
    func translate(content: String) {
        guard let apiTypeStr = UserDefaults.standard.string(forKey: .tanshuType),
              let type = TanshuAPIType(rawValue: apiTypeStr)
        else {
            return
        }
        guard let apiKey = UserDefaults.standard.string(forKey: .tanshuAPIKey) else {
            self.result.send(completion: .failure(ApiError.keyNotFound(.tanshu)))
            return
        }
        
        Task.detached(operation: {
            do {
                let result = try await TanshuAPI.shared.translate(content, apiKey: apiKey, type: type)
                self.result.send((true, result))
                self.result.send((false, ""))
            } catch {
                self.result.send(completion: .failure(.unknown(.tanshu, error)))
            }
        })
        
        self.logger.info("翻译[\(type)]已提交: \(content)")
    }
    
    func close() {
        // anyCancellable?.cancel()
        self.logger.info("已关闭.")
    }
}
