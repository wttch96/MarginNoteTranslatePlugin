//
//  ContentView.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import SwiftUI
import Combine

struct History: Identifiable {
    var id: String {
        return text
    }
    let text: String
    let result: String
}

struct ContentView: View {
    @Environment(\.openWindow) var openWindow
    @AppStorage("key") var tanshuKey: String?
    // 有道翻译
    @AppStorage("youdao-app-id") var youdaoAppId: String = ""
    @AppStorage("youdao-app-key") var youdaoAppKey: String = ""
    
    @State private var keywords: String = ""
    @State private var translateResult: String = ""
    @State private var anyCancellabel: AnyCancellable? = nil
    
    @State private var histories: [History] = []
    @State private var showHistory = false
    
    @AppStorage("float") private var float = true
    
    
    var body: some View {
        HStack {
            if showHistory {
                ScrollView {
                    VStack {
                        ForEach(histories.reversed(), id:\.text) { history in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(history.text)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                HStack {
                                    Text(history.result)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                            .padding(4)
                            .frame(width: 160)
                            .font(.footnote)
                            .background {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white.opacity(0.1))
                            }
                            .onTapGesture(perform: {
                                self.keywords = history.text
                                self.translateResult = history.result
                            })
                        }
                    }
                }
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Button(action: {
                        withAnimation(.spring) {
                            showHistory.toggle()
                        }
                    }, label: {
                        Image(systemName: "sidebar.left")
                    })
                    Button(action: {
                        openWindow(id: "SettingWindow")
                    }, label: {
                        Image(systemName: "gearshape.fill")
                    })
                    Spacer()
                    Image(systemName: "pin")
                        .bold()
                        .foregroundColor(.accentColor)
                        .rotationEffect(float ? .zero : .init(radians: .pi/4))
                        .animation(.spring, value: float)
                        .onTapGesture {
                            float.toggle()
                            if let window = NSApplication.shared.windows.first(where: { $0.title.contains("MarginNote插件")}) {
                                window.level = float ? .floating : .normal
                            }
                        }
                }
                VStack {
                    HStack(spacing: 0) {
                        Text("英文")
                            .font(.footnote)
                            .bold()
                            .offset(x: 4)
                        Spacer()
                    }
                    TextEditor(text: $keywords)
                        .bold()
                        .font(.title3)
                    
                    ZStack {
                        Rectangle()
                            .fill(.gray)
                            .frame(height: 1)
                        
                        Image(systemName: "arrow.triangle.swap")
                            .foregroundColor(.accentColor)
                            .padding(6)
                            .scaleEffect(y: -1)
                            .background {
                                Circle()
                                    .fill(.gray)
                            }
                    }
                    
                    HStack {
                        Text("结果")
                            .font(.footnote)
                            .bold()
                            .offset(x: 4)
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                    TextEditor(text: $translateResult)
                        .bold()
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    
                    
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                            .foregroundColor(.accentColor.opacity(0.6))
                            .onTapGesture {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(translateResult, forType: .string)
                            }
                        Spacer()
                    }
                }
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.black.opacity(0.2))
                }
            }
            .textEditorStyle(.plain)
        }
        .padding()
        .onOpenURL(perform: { url in
            if let url = url.absoluteString.removingPercentEncoding {
                keywords = url.replacing("WttchTranslate://keyword/", with: "")
                
//                if let key = key {
//                    anyCancellabel = TanshuAPI.shared.translate(keywords, key: key)
//                        .sink(receiveCompletion: { error in
//                            print(error)
//                        }, receiveValue: { result in
//                            self.translateResult = result
//                            histories.append(History(text: keywords, result: self.translateResult))
//                        })
//                }
                anyCancellabel = YoudaoAPI.shared.translate(keywords, appId: youdaoAppId, appKey: youdaoAppKey)
                    .sink { error in
                        print(error)
                    } receiveValue: { value in
                        print(value)
                    }

            }
        })
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray)
        }
    }
}

#Preview {
    ContentView()
}
