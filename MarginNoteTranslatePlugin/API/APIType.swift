//
//  API.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/30.
//

import Foundation
import SwiftUI


enum APIType: String, CaseIterable, Identifiable {
    case tanshu = "Tanshu"
    case youdao = "Youdao"
    case xunfei = "Xunfei"
    
    case deepseek = "Deepseek"
    
    var id: String {
        return self.rawValue
    }
}

extension APIType {
    var name: String {
        let names: [APIType: String] = [
            .tanshu: "探数",
            .youdao: "有道",
            .xunfei: "讯飞",
            .deepseek: "Deepseek"
        ]
        
        return names[self]!
    }
    
    var color: Color {
        let colors: [APIType: Color] = [
            .tanshu: .green,
            .youdao: .red,
            .xunfei: .blue,
            .deepseek: .blue
        ]
        return colors[self]!
    }
}
