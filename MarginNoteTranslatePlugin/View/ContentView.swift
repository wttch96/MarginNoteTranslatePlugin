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

@Log("翻译页面", level: .debug)
struct ContentView: View {
    @Environment(\.openWindow) var openWindow
    
    @StateObject private var vm = ContentViewModel()
    @AppStorage("float") private var float = false
    @Namespace private var namespace
    
    @AppStorage(.apiType) private var apiType: APIType = .tanshu
    @AppStorage(.tanshuType) private var tanshuType: TanshuAPIType = .deepl
    
    @State private var layout: Edge.Set = .horizontal
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
//                    Button(action: {}, label: {
//                        Image(systemName: "square.and.line.vertical.and.square")
//                    })
//                    .buttonStyle(.accessoryBar)
//
                Spacer()
                if vm.concise {
                    conciseToggle
                        .font(.footnote)
                }
            }
            VStack(spacing: 0) {
                TextField("", text: $vm.keywords)
                    .textFieldStyle(.plain)
                    .bold()
                    .font(.subheadline)
                    .padding(4)
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.primary.opacity(0.2))
                    }
                    .onSubmit {
                        vm.translate(api: apiType, tanshuType: tanshuType)
                    }
                    .padding(8)
                
                ZStack {
                    VStack {
                        HStack {
                            Text(vm.translateResult)
                                .bold()
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                                .padding(4)
                            Spacer()
                        }
                        Spacer()
                    }
                    .background(.white.opacity(0.1))
                        
                    VStack {
                        Spacer()
                            
                        HStack {
                            if vm.transalting {
                                Text("处理中...")
                                    .font(.footnote)
                                    .foregroundColor(.accentColor)
                            }
                            if !vm.transalting && !vm.translateResult.isEmpty {
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
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(.thinMaterial)
        .textEditorStyle(.plain)
        .frame(maxWidth: 680)
        .toolbar(removing: .title)
        .clip(vm.concise)
        .onOpenURL(perform: onOpenURL)
        .onAppear {
            self.onConciseChange(false, self.vm.concise)
            self.vm.switchService(apiType: apiType)
        }
        .onChange(of: vm.concise, onConciseChange(_:_:))
        .onChange(of: apiType) { _, newValue in self.vm.switchService(apiType: newValue) }
        .toolbar(content: { toolbars })
    }
}

// MARK: 行为

extension ContentView {
    /// 监听 URL
    /// - Parameter url: URL 链接, 格式为 `WttchTranslate://keyword/要翻译文本`
    private func onOpenURL(_ url: URL) {
        // Step 1: 将当前应用移到后台
        NSApplication.shared.deactivate()
        
        logger.debug("url: \(url)")

        // Step 2: 获取当前应用的进程 ID
        let currentAppPID = NSRunningApplication.current.processIdentifier

        // Step 3: 找到所有运行的应用程序，并排除当前应用
        let runningApps = NSWorkspace.shared.runningApplications

        // Step 4: 激活上一个应用（选择最近非当前应用且处于活跃的应用）
        if let previousApp = runningApps.first(where: { app in
            let appName = app.localizedName ?? ""
            return appName.contains("MarginNote 4")
        }) {
            previousApp.activate(options: [.activateIgnoringOtherApps])
        }
        
        guard let urlSchemeEntity = URLSchemeParser.parse(url: url) else { return }
        switch urlSchemeEntity.type {
        case .selection:
            vm.keywords = urlSchemeEntity.data
        case .note:
            guard let data = urlSchemeEntity.data.data(using: .utf8),
                  let note = try? JSONDecoder().decode(NoteEntity.self, from: data) else { return }
            
            if let keywords = note.keywords {
                vm.keywords = keywords
            }
            
        default:
            break
        }
        
        if vm.autoTransaltae {
            vm.translate(api: apiType, tanshuType: tanshuType)
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
        window.layoutIfNeeded()
        window.toolbarStyle = .unifiedCompact
        window.isMovableByWindowBackground = vm.concise
        window.level = float ? .floating : .normal
    }
}

// MARK: 子视图

extension ContentView {
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
    
    @ViewBuilder
    private var apiPicker: some View {
        Picker("翻译API", selection: $apiType, content: {
            ForEach(APIType.allCases) { api in
                Text(api.name)
                    .tag(api)
            }
        })
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
//            if showNavigation == .detailOnly {
//                ToolbarItem(placement: .navigation) {
//                    navigationToggle
//                }
//            }
            ToolbarItem(placement: .secondaryAction) {
                apiPicker
//                HStack(spacing: 0) {
//                    Text(apiType.name)
//                    if apiType == .tanshu {
//                        Text(" | \(tanshuType.rawValue)")
//                    }
//                }
//                .font(.footnote)
//                .foregroundColor(apiType.color)
//                .padding(.vertical, 2)
//                .padding(.horizontal, 4)
//                .background(
//                    RoundedRectangle(cornerRadius: 2)
//                        .stroke(apiType.color, lineWidth: 1)
//                )
//                .onTapGesture {
//                    openWindow(id: "SettingWindow")
//                }
            }
            if apiType == .deepseek {
                deepseekServiceTypePicker
            }
            ToolbarItem(placement: .secondaryAction) {
                autoTranslateButton
            }
            ToolbarItem(placement: .secondaryAction) {
                Button(action: {
                    vm.translate(api: apiType, tanshuType: tanshuType)
                }, label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.accentColor)
                })
            }
            ToolbarItem(placement: .cancellationAction, content: {
                Image(systemName: "gearshape")
                    .onTapGesture {
                        openWindow(id: "SettingWindow")
                    }
            })
            ToolbarItem(placement: .cancellationAction, content: {
                conciseToggle
            })
            ToolbarItem(placement: .cancellationAction, content: {
                pinButton
            })
        }
    }
    
    // deepseek 服务选择
    @ToolbarContentBuilder
    private var deepseekServiceTypePicker: some ToolbarContent {
        ToolbarItem(placement: .secondaryAction, content: {
            Picker("", selection: $vm.deepseekType, content: {
                ForEach(DeepseekServiceType.allCases, id: \.rawValue) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            })
        })
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContentView()
}
