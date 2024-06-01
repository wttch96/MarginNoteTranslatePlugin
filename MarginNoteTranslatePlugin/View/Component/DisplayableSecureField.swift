//
//  DisplayableSecureField.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/30.
//

import SwiftUI

struct DisplayableSecureField: View {
    let title: String
    @Binding var text: String
    @State private var showSecure = false
    
    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
        self.showSecure = showSecure
    }
    
    var body: some View {
        HStack {
            if showSecure {
                TextField(title, text: _text)
            } else {
                SecureField(title, text: _text)
            }
            
            Image(systemName: showSecure ? "eye" : "eye.slash")
                .onTapGesture {
                    withAnimation {
                        showSecure.toggle()
                    }
            }
        }
    }
}

#Preview {
    Form {
        Section {
            DisplayableSecureField("测试:",  text: .constant("Text Example"))
        }
    }
    .formStyle(.grouped)
}
