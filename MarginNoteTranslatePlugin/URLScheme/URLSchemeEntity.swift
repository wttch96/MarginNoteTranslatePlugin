//
//  URLSchemeEntity.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/12/31.
//

import Foundation

struct URLSchemeEntity {
    let type: URLSchemeType?
    let data: String
}

enum URLSchemeType: String {
    case selection
    case note
}

struct NoteEntity: Decodable {
    let title: String?
    let comments: [Comment]?
    let excerpt: String?

    
    ///
    /// https://github.com/ourongxing/ohmymn/blob/b0bb5f16e20c9cb5e8d8d5c6d411eb39b8b10aac/packages/docs/api/marginnote/mbbooknote.md
    struct Comment: Decodable {
        let type: String
        let text: String?
        let q_htext: String?
    }
}

extension NoteEntity {
    var keywords: String? {
        guard var keywords = self.excerpt else {
            return nil
        }
        
        self.comments?.filter({ $0.type == "LinkNote"}).forEach({ comment in
            keywords += comment.q_htext ?? ""
            keywords += "\n"
        })
        
        return keywords
    }
}
