//
//  DeepseekService.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2025/6/12.
//

import Combine
import SwiftLogMacro
import SwiftUI

enum DeepseekServiceType: String, CaseIterable {
    case translate = "翻译"
    case summary = "总结"
}


@Log("Deepseek")
class DeepseekService: BaseService, TranslateService {
    private var _type: DeepseekServiceType = .translate
    private var type: Published<DeepseekServiceType>.Publisher
    private var anyCancellable: AnyCancellable? = nil

    private var api: DeepseekAPI? = nil
    init(
        type: Published<DeepseekServiceType>.Publisher)
    {
        self.type = type

        super.init()
        self.anyCancellable = type.sink(receiveValue: { newValue in
            self._type = newValue
            self.logger.info("已使用:\(self._type)")
        })
    }

    func translate(content: String) {
        self.logger.info("[\(self._type)]已提交: \(content)")
        let apiKey = UserDefaults.standard.string(forKey: .deepseekKey)
        var prompt: String? = nil
        if self._type == .translate {
            prompt = UserDefaults.standard.string(forKey: .deepseekTranslatePrompt‌)
        }
        if self._type == .summary {
            prompt = UserDefaults.standard.string(forKey: .deepseekSummaryPrompt)
        }

        guard let apiKey = apiKey, let prompt = prompt,
              !apiKey.isEmpty, !prompt.isEmpty
        else {
            // 配置获取失败
            result.send(completion: .failure(ApiError.keyNotFound(.deepseek)))
            return
        }

        self.api = DeepseekAPI(apiKey: apiKey, prompt: prompt)
        self.api?.consume = { ret in
            switch ret {
            case .completed:
                self.result.send((false, ""))
            case .content(let content):
                self.result.send((true, content))
            case .failure(let error):
                self.result.send(completion: .failure(ApiError.unknown(.deepseek, error)))
            }
        }
        self.api?.completionsStream(content: content)
    }

    func close() {
        self.anyCancellable?.cancel()
    }
}
