//
//  SettingKeys.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/10/8.
//

import Foundation
import SwiftUI

enum SettingKeys: String {
    case tanshuAPIKey = "Tanshu-APIKey"
    
    case youdaoAppID = "youdao-app-id"
    case youdaoAppKey = "youdao-app-key"
    
    case xunfeiAppID = "Xunfei-AppID"
    case xunfeiAppSecret = "Xunfei-AppSecret"
    case xunfeiAppKey = "Xunfei-AppKey"
    
    // deepseek 相关的key
    case deepseekKey = "deepseek-api-key"
    case deepseekTranslatePrompt‌ = "deepseek-translate-prompt"
    case deepseekSummaryPrompt = "deepseek-summary-prompt"
    
    // API 类型
    case apiType = "API-Type"
    // 探数翻译类型
    case tanshuType = "Tanshu-Type"
    
    // 窗口悬浮
    case windowFloat = "window-float"
}


extension AppStorage {
    init(wrappedValue: Value, _ key: SettingKeys, store: UserDefaults? = nil) where Value == String {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
    
    init(wrappedValue: Value, _ key: SettingKeys, store: UserDefaults? = nil) where Value == APIType {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
    
    init(wrappedValue: Value, _ key: SettingKeys, store: UserDefaults? = nil) where Value == TanshuAPIType {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
    
    init(wrappedValue: Value, _ key: SettingKeys, store: UserDefaults? = nil) where Value == Bool {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
}

extension UserDefaults {
    func string(forKey: SettingKeys) -> String? {
        return self.string(forKey: forKey.rawValue)
    }
    
    func object(forKey: SettingKeys) -> Any? {
        return self.object(forKey: forKey.rawValue)
    }
}
