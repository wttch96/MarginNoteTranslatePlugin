//
//  ContentViewModel.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/30.
//

import Foundation
import Combine


class ContentViewModel: ObservableObject {
    // 使用的 API
    @Published var api: APIType = .tanshu
    
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
    
    public func translate() {
        guard !transalting else {
            // 多次提交
            return
        }
        
        print("[\(api.name)]翻译已提交...")
        
        transalting = true
        error = nil
        
        if api == .tanshu {
            anyCancellabel = TanshuAPI.shared.translate(keywords)
                .sink(receiveCompletion: { completion in
                    
                }, receiveValue: { data in
                })
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
                        }
                    }
                    self.transalting = false
                }, receiveValue: { data in
                    self.translateResult = data.translation?.first ?? "<None>"
                })

            return
        }
    }
}
