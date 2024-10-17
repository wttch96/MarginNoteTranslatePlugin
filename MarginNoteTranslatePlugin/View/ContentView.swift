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
    @State private var showNavigation = NavigationSplitViewVisibility.all
    @AppStorage("float") private var float = false
    @Namespace private var namespace
    
    var body: some View {
        NavigationSplitView(columnVisibility: $showNavigation) {
            historyView
                .toolbar(removing: .sidebarToggle)
                .toolbar {
                    if showNavigation != .detailOnly {
                        ToolbarItem(placement: .principal) {
                            navigationToggle
                        }
                    }
                }
        } detail: {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Spacer()
                        
                    if vm.concise {
                        conciseToggle
                            .font(.footnote)
                    }
                }
                TextEditor(text: $vm.keywords)
                    .bold()
                    .font(.subheadline)
                    .padding(4)
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.primary.opacity(0.2))
                    }
                    .onSubmit {
                        vm.translate()
                    }

                ZStack {
                    TextEditor(text: $vm.translateResult)
                        .bold()
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .padding(4)
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.secondary.opacity(0.2))
                        }
                        .disabled(true)
                        
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
                .padding(.top, 8)
            }
            .padding(8)
            .background(.thinMaterial)
            .textEditorStyle(.plain)
            .frame(maxWidth: 680)
        }
        .clip(vm.concise)
        .onOpenURL(perform: onOpenURL)
        .onAppear {
            self.onConciseChange(false, self.vm.concise)
        }
        .onChange(of: vm.concise, onConciseChange(_:_:))
        .toolbar(content: { toolbars })
    }
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
    private func onConciseChange(_ _: Bool, _: Bool) {
        guard let window = NSApplication.shared.windows.first else { return }
        if vm.concise {
            // 简洁模式
            window.styleMask = [.borderless, .resizable]
            window.backgroundColor = .clear
            window.hasShadow = false
            // showNavigation = (showNavigation == .all) ? .detailOnly : showNavigation
        } else {
            // 正常模式
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.backgroundColor = NSColor.windowBackgroundColor
            window.hasShadow = true
        }
        window.toolbarStyle = .unifiedCompact
        window.isMovableByWindowBackground = vm.concise
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
    
    @ViewBuilder
    private var navigationToggle: some View {
        Button(action: {
            withAnimation {
                if showNavigation == .all {
                    showNavigation = .detailOnly
                } else if showNavigation == .detailOnly {
                    showNavigation = .all
                }
            }
        }) {
            Image(systemName: "sidebar.leading")
        }
        .matchedGeometryEffect(id: "sidebarToggle", in: namespace)
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
                if let window = NSApplication.shared.windows.first {
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
            if showNavigation == .detailOnly {
                ToolbarItem(placement: .navigation) {
                    navigationToggle
                }
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
