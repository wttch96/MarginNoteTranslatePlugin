//
//  ContentView.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import SwiftUI
import Combine

struct ContentView: View {
    @Environment(\.openWindow) var openWindow
    @AppStorage("key") var key: String?
    
    @State private var keywords: String = ""
    @State private var translateResult: String = ""
    @State private var anyCancellabel: AnyCancellable? = nil
    
    
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image(systemName: "pin")
                }
                Button(action: {
                    openWindow(id: "SettingWindow")
                }, label: {
                    Image(systemName: "gearshape.fill")
                })
                
                Text("接受到的文本:")
                TextEditor(text: $keywords)
                    .disabled(true)
                Divider()
                Text("翻译结果:")
                TextEditor(text: $translateResult)
                    .disabled(true)
                
                Button(action: {
                    
                    
                }, label: {
                    Image(systemName: "doc.on.doc.fill")
                    Text("复制")
                })
            }
            .textEditorStyle(.plain)
        }
        .padding()
        .onOpenURL(perform: { url in
            if let url = url.absoluteString.removingPercentEncoding {
                keywords = url.replacing("WttchTranslate://keyword/", with: "")
                
                if let key = key {
                    anyCancellabel = TanshuAPI.shared.translate(keywords, key: key)
                        .sink(receiveCompletion: { error in
                            print(error)
                        }, receiveValue: { result in
                            self.translateResult = result
                        })
                }
            }
        })
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray)
        }
        .frame(width: 400)
    }
}

#Preview {
    ContentView()
}
