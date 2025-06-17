//
//  ContentViewModel.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/30.
//

import Combine
import Foundation
import SwiftLogMacro

@Log("ContentView", level: .debug)
@MainActor
class ContentViewModel: ObservableObject {
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
    
    @Published var deepseekType: DeepseekServiceType = .translate
    
    
    private var api: TranslateService? = nil
    private var apiCancells: Set<AnyCancellable> = Set()

    func switchService(apiType: APIType) {
        // 取消订阅
        api?.close()
        for cancellable in apiCancells {
            cancellable.cancel()
        }
        
        switch apiType {
        case .deepseek:
            api = DeepseekService(type: $deepseekType)
        case .tanshu:
            api = TanshuService()
        default:
            api = nil
        }
        guard let api = api else { return }
        // 订阅
        api.result.receive(on: DispatchQueue.main)
            .sink { compltion in
                switch compltion {
                case .finished:
                    self.transalting = false
                case .failure(let error):
                    self.transalting = false
                    self.error = error.localizedDescription
                }
                
            } receiveValue: { translating, content in
                self.transalting = translating
                if self.transalting {
                    self.translateResult += content
                }
            }
            .store(in: &apiCancells)

        logger.debug("切换api为: \(apiType.name)")
    }
    
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
            } catch {
                self.handleError(error: error)
            }
            
            self.transalting = false
        }
    }
    
    
    public func translate(api: APIType, tanshuType: TanshuAPIType) {
        guard !keywords.isEmpty else {
            self.logger.info("翻译内容为空!")
            return
        }
        if let service = self.api {
            logger.info("[\(api.name)]翻译已提交...")
            
            service.translate(content: keywords)
        } else { return }
        
        guard !transalting && !keywords.isEmpty else {
            // 多次提交
            return
        }
        
        transalting = true
        error = nil
        translateResult = ""
    
//        if let deepseekAPI = deepseekAPI {
//            deepseekAPI.completionsStream(content: keywords)
//            return
//        }
        
//        if api == .tanshu {
//            tanshuTranslate(keywords, tanshuType: tanshuType)
//            return
//        }
//        if api == .xunfei {
//            xunfeiTranslate(keywords)
//            return
//        }
//        if api == .youdao {
//            anyCancellabel = YoudaoAPI.shared.translate(keywords)
//                .sink(receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        break
//                    case .failure(let error):
//                        switch error {
//                        case .keyNotFound(let type):
//                            self.error = "[\(type.name)]API Key 未找到, 请在设置中配置..."
//                        case .serviceError(let type, let code):
//                            self.error = "[\(type.name)]服务错误: 代码(\(code)."
//                        case .unknown(let apiType, let error):
//                            self.error = "[\(apiType.name)]未知错误: \(type(of: error)): \(error.localizedDescription)"
//                        case .url(let apiType, let urlString):
//                            self.error = "URL 错误: \(urlString)"
//                        }
//                    }
//                    self.transalting = false
//                }, receiveValue: { data in
//                    self.translateResult = data.translation?.first ?? "<None>"
//                })
//
//            return
//        }
    }
}
