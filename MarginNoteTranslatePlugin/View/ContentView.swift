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
    
    
    @StateObject private var vm = ContentViewModel()
    
    @State private var histories: [History] = []
    @State private var showHistory = false
    @AppStorage("float") private var float = false
    
    
    var body: some View {
        HStack {
            if showHistory {
                historyView
            }
            
            VStack(alignment: .leading) {
                VStack {
                    HStack(spacing: 0) {
                        Text("英文")
                            .font(.footnote)
                            .bold()
                            .offset(x: 4)
                        Spacer()
                    }
                    TextEditor(text: $vm.keywords)
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
                    TextEditor(text: $vm.translateResult)
                        .bold()
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    
                    
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                            .foregroundColor(.accentColor.opacity(0.6))
                            .onTapGesture {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(vm.translateResult, forType: .string)
                            }
                        Spacer()
                        
                        if let error = vm.error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                }
            }
            .textEditorStyle(.plain)
        }
        .padding()
        .onOpenURL(perform: { url in
            if let url = url.absoluteString.removingPercentEncoding {
                vm.keywords = url.replacing("WttchTranslate://keyword/", with: "")
                vm.translate()
            }
        })
//        .background {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(.bar)
//        }
        .toolbar(content: {
            ToolbarItem( placement: .navigation,  content: {
                historyButton
            })
            ToolbarItem(placement: .navigation) {
                settingButton
            }
            ToolbarItem(placement: .navigation) {
                apiPicker
            }
            ToolbarItem(placement: .cancellationAction, content: {
                pinButton
            })
        })
    }
}


// MARK: 子视图
extension ContentView {
    // 左侧历史记录
    @ViewBuilder
    private var historyView: some View {
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
                        self.vm.keywords = history.text
                        self.vm.translateResult = history.result
                    })
                }
            }
        }
    }
    
    // 使用的 API 的选择器
    @ViewBuilder
    private var apiPicker: some View {
        Picker("", selection: $vm.api, content: {
            ForEach(APIType.allCases) { api in
                Text(api.name)
                    .tag(api)
            }
        })
        .frame(width: 120)
    }
    
    // 显示历史记录的 Button
    @ViewBuilder
    private var historyButton: some View {
        Button(action: {
            withAnimation(.spring) {
                showHistory.toggle()
            }
        }, label: {
            Image(systemName: "sidebar.left")
                .font(.title3)
                .offset(y: 1.5)
        })
    }
    
    // 打开设置页面的 Button
    @ViewBuilder
    private var settingButton: some View {
        Button(action: {
            openWindow(id: "SettingWindow")
        }, label: {
            Image(systemName: "gearshape.fill")
        })
    }
    
    // pin Button
    @ViewBuilder
    private var pinButton: some View {
        Image(systemName: "pin")
            .bold()
            .foregroundColor(.accentColor)
            .rotationEffect(float ? .zero : .init(radians: .pi/4))
            .animation(.spring, value: float)
            .onTapGesture {
                float.toggle()
                if let window = NSApplication.shared.windows.first(where: { $0.title == ""}) {
                    window.level = float ? .floating : .normal
                }
            }
    }
}


#Preview {
    ContentView()
}
