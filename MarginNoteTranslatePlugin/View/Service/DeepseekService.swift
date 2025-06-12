//
//  DeepseekService.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2025/6/12.
//

import Combine
import SwiftUI

enum DeepseekServiceType: String, CaseIterable {
    case translate = "翻译"
    case summary = "总结"
}

class BaseService {
    var translatin: Published<Bool>.Publisher
    var result: Published<String>.Publisher
    var error: Published<String?>.Publisher

    init(translatin: Published<Bool>.Publisher, result: Published<String>.Publisher, error: Published<String?>.Publisher) {
        self.translatin = translatin
        self.result = result
        self.error = error
    }
}

class DeepseekService: ViewService {
    private var type: Binding<DeepseekServiceType>

    init(type: Binding<DeepseekServiceType>) {
        self.type = type
    }

    @ToolbarContentBuilder
    var secondPicker: some ToolbarContent {
        ToolbarItem {
            Picker("", selection: type, content: {
                ForEach(DeepseekServiceType.allCases, id: \.rawValue) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            })
        }
    }
}
