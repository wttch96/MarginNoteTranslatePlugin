//
//  URLSchemeParser.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/12/31.
//

import Foundation

enum URLSchemeParser {}

extension URLSchemeParser {
    static func parse(url: URL) -> URLSchemeEntity? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }

        // 将参数解析为字典
        var params: [String: [String]] = [:]
        for item in queryItems {
            params[item.name, default: []].append(item.value ?? "")
        }

        guard let type = params["type"]?.first,
              let type = URLSchemeType(rawValue: type),
              let data = params["data"]?.first,
              let data = data.removingPercentEncoding else { return nil }

        return URLSchemeEntity(type: type, data: data)
    }
}
