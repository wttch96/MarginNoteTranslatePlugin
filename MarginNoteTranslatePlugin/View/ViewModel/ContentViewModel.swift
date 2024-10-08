//
//  ContentViewModel.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/30.
//

import Combine
import Foundation
import SwiftLogMacro

@Log
@MainActor
class ContentViewModel: ObservableObject {
    // 使用的 API
    @Published var api: APIType = .tanshu
    // 探数 API 使用的翻译引擎
    @Published var tanshuType: TanshuAPIType = .deepl
    
    // 要翻译的文本
    @Published var keywords: String = ""
    // 翻译结果
    @Published var translateResult: String = ""
    // 翻译任务
    @Published var anyCancellabel: AnyCancellable? = nil
    // 翻译中
    @Published var transalting = false
    // 是否出错
    @Published var error: String? = nil
    // 是否自动翻译
    @Published var autoTransaltae = true
    
    @Published var from: Language = .en
    @Published var to: Language = .zh
    
    // 简洁模式
    @Published var concise: Bool = false
    
    @Published var histories: [History] = []
    
    private func handleError(error: (any Error)?) {
        guard let error = error as? ApiError else { return }
        
        switch error {
        case .keyNotFound(let type):
            self.error = "[\(type.name)]API Key 未找到, 请在设置中配置..."
        case .serviceError(let type, let code):
            self.error = "[\(type.name)]服务错误: 代码(\(code)."
        case .unknown(let apiType, let error):
            self.error = "[\(apiType.name)]未知错误: \(type(of: error)): \(error.localizedDescription)"
        case .url(_, let urlString):
            self.error = "URL 错误: \(urlString)"
        }
    }
    
    /// 使用探数 API 进行翻译
    /// - Parameter keywords: 要翻译的文本
    public func tanshuTranslate(_ keywords: String) {
        guard let apiKey = UserDefaults.standard.string(forKey: TanshuAPI.apiKey) else {
            error = "[\(APIType.tanshu.name)]API Key 未找到, 请在设置中配置..."
            transalting = false
            return
        }
        Task.detached { @MainActor in
            do {
                let result = try await TanshuAPI.shared.translate(self.keywords, apiKey: apiKey, type: self.tanshuType)
                self.translateResult = result
                self.histories.append(History(api: .tanshu, text: self.keywords, result: self.translateResult))
            } catch {
                self.handleError(error: error)
            }
            self.transalting = false
        }
    }
    
    public func xunfeiTranslate(_ keywords: String) {
        guard let appID = UserDefaults.standard.string(forKey: .xunfeiAppID),
              let apiSecret = UserDefaults.standard.string(forKey: .xunfeiAppSecret),
              let apiKey = UserDefaults.standard.string(forKey: .xunfeiAppKey)
        else {
            error = "[\(APIType.xunfei.name)]API Key 未找到, 请在设置中配置..."
            transalting = false
            return
        }
        
        Task.detached { @MainActor in
            do {
                let result = try await XunfeiAPI.shared.translate(keywords, secret: XunfeiAPISecret(appID: appID, secret: apiSecret, key: apiKey), from: self.from, to: self.to)
                self.translateResult = result
                self.histories.append(History(api: .xunfei, text: self.keywords, result: self.translateResult))
            } catch {
               self.handleError(error: error)
            }
            
            self.transalting = false
        }
    }
    
    public func translate() {
        guard !transalting && !keywords.isEmpty else {
            // 多次提交
            return
        }
        
        logger.info("[\(api.name)]翻译已提交...")
        
        transalting = true
        error = nil
        translateResult = ""
        
        if api == .tanshu {
            tanshuTranslate(keywords)
            return
        }
        if api == .xunfei {
            xunfeiTranslate(keywords)
            return
        }
        if api == .youdao {
            anyCancellabel = YoudaoAPI.shared.translate(keywords)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        switch error {
                        case .keyNotFound(let type):
                            self.error = "[\(type.name)]API Key 未找到, 请在设置中配置..."
                        case .serviceError(let type, let code):
                            self.error = "[\(type.name)]服务错误: 代码(\(code)."
                        case .unknown(let apiType, let error):
                            self.error = "[\(apiType.name)]未知错误: \(type(of: error)): \(error.localizedDescription)"
                        case .url(let apiType, let urlString):
                            self.error = "URL 错误: \(urlString)"
                        }
                    }
                    self.transalting = false
                }, receiveValue: { data in
                    self.translateResult = data.translation?.first ?? "<None>"
                    self.histories.append(History(api: .youdao, text: self.keywords, result: self.translateResult))
                })

            return
        }
    }
}
