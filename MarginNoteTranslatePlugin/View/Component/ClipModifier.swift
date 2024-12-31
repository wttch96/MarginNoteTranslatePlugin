//
//  ClipModifier.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/10/16.
//

import Foundation
import SwiftUI

struct ClipModifier: ViewModifier {
    let clip: Bool
    
    func body(content: Content) -> some View {
        if clip {
            content
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            content
        }
    }
}

extension View {
    func clip(_ clip: Bool) -> some View {
        self.modifier(ClipModifier(clip: clip))
    }
}
