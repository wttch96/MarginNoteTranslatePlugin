//
//  PasteboardButton.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/6/1.
//

import SwiftUI
import Combine

struct PasteboardButton: View {
    let text: String
    
    @State private var showPasted = false
    
    @State private var anyCancellable: AnyCancellable? = nil
    
    
    var body: some View {
        Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            showPasted = true
            anyCancellable = Just("")
                .delay(for: 1, scheduler: DispatchQueue.main)
                .sink(receiveValue: { _ in
                    showPasted = false
                })
        }, label: {
            HStack {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.accentColor)
                if showPasted {
                    Text("已复制到粘贴板...")
                }
                Spacer()
            }
            .font(.subheadline)
            .frame(width: 200)
        })
        .buttonStyle(PlainButtonStyle())
        .padding(4)
    }
}

#Preview {
    PasteboardButton(text: "AAA")
        .frame(width: 120)
}
