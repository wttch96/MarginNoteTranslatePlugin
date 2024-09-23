//
//  Language.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/6/6.
//

import Foundation


enum Language: CaseIterable {
    case en
    case zh
}

extension Language {
    var name: String {
        let names: [Language: String] = [
            .en: "英",
            .zh: "中"
        ]
        
        return names[self]!
    }
}
