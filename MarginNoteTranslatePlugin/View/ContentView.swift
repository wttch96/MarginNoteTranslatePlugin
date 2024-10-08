//
//  ContentView.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import AppKit
import ApplicationServices
import Combine
import SwiftLogMacro
import SwiftUI

struct History: Identifiable {
    let id: String = UUID().uuidString
    let api: APIType
    let text: String
    let result: String
}

@Log("翻译页面", level: .debug)
struct ContentView: View {
    @Environment(\.openWindow) var openWindow
    
    @StateObject private var vm = ContentViewModel()
    
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
//                        Menu(vm.from.name, content: {
//                            ForEach(Language.allCases, id: \.self) { lang in
//                                Button(action: {
//                                    self.vm.from = lang
//                                }, label: {
//                                    Text(lang.name)
//                                })
//                            }
//                        })
//                        .menuStyle(BorderlessButtonMenuStyle())
//                        .font(.footnote)
//                        .frame(width: 40)
                        Spacer()
                        
                        if vm.concise {
                            conciseToggle
                        }
                    }
                    TextEditor(text: $vm.keywords)
                        .bold()
                        .font(.subheadline)
                    
                    if !vm.concise {
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
                                .onTapGesture {
                                    vm.translate()
                                }
                        }
                    }
                    ZStack {
                        TextEditor(text: $vm.translateResult)
                            .bold()
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        
                        VStack {
                            Spacer()
                            
                            HStack {
                                if !vm.translateResult.isEmpty {
                                    PasteboardButton(text: vm.translateResult)
                                }
                                Spacer()
                                
                                if let error = vm.error {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial)
            }
            .textEditorStyle(.plain)
        }
        .onOpenURL(perform: onOpenURL)
        .clipShape(vm.concise ? AnyShape(RoundedRectangle(cornerRadius: 8)) : AnyShape(Rectangle()))
        .toolbar(content: { toolbars })
        .onAppear {
            self.onConciseChange(false, self.vm.concise)
        }
        .onChange(of: vm.concise, onConciseChange(_:_:))
    }
}

// 获取指定应用程序的窗口列表
func getWindowsOfApplication(_ app: NSRunningApplication) -> [AXUIElement] {
    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var windowList: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)
    
    if result == .success, let windows = windowList as? [AXUIElement] {
        return windows
    }
    return []
}

// 获取窗口的标题
func getWindowTitle(_ window: AXUIElement) -> String? {
    var title: AnyObject?
    let result = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title)
    
    if result == .success {
        return title as? String
    }
    return nil
}

// MARK: 行为

extension ContentView {
    /// 监听 URL
    /// - Parameter url: URL 链接, 格式为 `WttchTranslate://keyword/要翻译文本`
    private func onOpenURL(_ url: URL) {
        if let url = url.absoluteString.removingPercentEncoding {
            let keywords = url.replacing("WttchTranslate://keyword/", with: "")
            vm.keywords = keywords
            logger.debug("收到翻译:\(keywords)")
            if vm.autoTransaltae {
                vm.translate()
            }
        }
    }
    
    /// 精简模式切换
    private func onConciseChange(_ _: Bool, _ concise: Bool) {
        guard let window = NSApplication.shared.windows.first else { return }
        if concise {
            // 简洁模式
            window.styleMask = [.borderless, .resizable]
            window.backgroundColor = .clear
            window.hasShadow = false
        } else {
            // 正常模式
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.backgroundColor = .gray
            window.hasShadow = true
        }
        window.isMovableByWindowBackground = float
        window.level = float ? .floating : .normal
    }
}

// MARK: 子视图

extension ContentView {
    // 左侧历史记录
    @ViewBuilder
    private var historyView: some View {
        ScrollView {
            VStack {
                ForEach(vm.histories.reversed(), id: \.text) { history in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(history.api.name)
                                .font(.system(size: 8))
                                .padding(2)
                                .background(content: {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(history.api.color)
                                })
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
        .frame(width: 160)
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
        .frame(width: 72)
    }
    
    @ViewBuilder
    // 探数 API 翻译引擎选择
    private var tanshuTypePicker: some View {
        Picker("", selection: $vm.tanshuType) {
            ForEach(TanshuAPIType.allCases, id: \.rawValue) { api in
                Text(api.rawValue)
                    .tag(api)
            }
        }
        .frame(width: 72)
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
    
    // 简洁模式
    @ViewBuilder
    private var conciseToggle: some View {
        Image(systemName: vm.concise ? "plus.circle" : "minus.circle")
            .foregroundColor(.accentColor)
            .onTapGesture {
                vm.concise.toggle()
            }
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
            .rotationEffect(float ? .zero : .init(radians: .pi / 4))
            .animation(.spring, value: float)
            .onTapGesture {
                float.toggle()
                if let window = NSApplication.shared.windows.first(where: { $0.title == "" }) {
                    window.level = float ? .floating : .normal
                }
            }
    }
    
    // 自动翻译
    @ViewBuilder
    private var autoTranslateButton: some View {
        Toggle("自动翻译", isOn: $vm.autoTransaltae)
            .toggleStyle(.checkbox)
    }
    
    // 工具栏
    @ToolbarContentBuilder
    private var toolbars: some ToolbarContent {
        if !vm.concise {
            ToolbarItem(placement: .navigation, content: {
                historyButton
            })
            ToolbarItem(placement: .navigation) {
                settingButton
            }
            ToolbarItem(placement: .navigation) {
                apiPicker
            }
            if vm.api == .tanshu {
                ToolbarItem(placement: .navigation) {
                    tanshuTypePicker
                }
            }
            ToolbarItem(placement: .navigation) {
                autoTranslateButton
            }
            ToolbarItem(placement: .cancellationAction, content: {
                conciseToggle
            })
            ToolbarItem(placement: .cancellationAction, content: {
                pinButton
            })
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContentView()
}
