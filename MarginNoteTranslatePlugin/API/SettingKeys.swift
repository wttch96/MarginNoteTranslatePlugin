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
    
    case xunfeiAppID = "Xunfei-AppID"
    case xunfeiAppSecret = "Xunfei-AppSecret"
    case xunfeiAppKey = "Xunfei-AppKey"
}


extension AppStorage {
    init(wrappedValue: Value, _ key: SettingKeys, store: UserDefaults? = nil) where Value == String {
        self.init(wrappedValue: wrappedValue, key.rawValue, store: store)
    }
}

extension UserDefaults {
    func string(forKey: SettingKeys) -> String? {
        return self.string(forKey: forKey.rawValue)
    }
}