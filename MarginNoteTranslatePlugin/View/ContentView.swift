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
    @AppStorage(.windowFloat) private var float = false
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
        .onOpenURL(perform: onOpenURL)
        .onAppear {
            self.vm.switchService(apiType: apiType)
            
            self.changeWindowFloat()
        }
        .onChange(of: apiType) { _, newValue in self.vm.switchService(apiType: newValue) }
        .toolbar(content: { toolbars })
    }
}

// MARK: 行为

extension ContentView {
    
    /// 修改窗口悬浮状态
    private func changeWindowFloat() {
        WindowContext.shared.mainWindow { window in
            window.level = float ? .floating : .normal
        }
    }
    
    
    /// 监听 URL
    /// - Parameter url: URL 链接, 格式为 `WttchTranslate://keyword/要翻译文本`
    private func onOpenURL(_ url: URL) {
        // Step 1: 将当前应用移到后台
        NSApplication.shared.deactivate()
        
        logger.debug("url: \(url)")

        // Step 2: 获取当前应用的进程 ID
        _ = NSRunningApplication.current.processIdentifier

        // Step 3: 找到所有运行的应用程序，并排除当前应用
        let runningApps = NSWorkspace.shared.runningApplications

        // Step 4: 激活上一个应用（选择最近非当前应用且处于活跃的应用）
        if let previousApp = runningApps.first(where: { app in
            let appName = app.localizedName ?? ""
            return appName.contains("MarginNote 4")
        }) {
            previousApp.activate(options: [])
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
}

// MARK: 子视图

extension ContentView {
    // 自动翻译
    @ToolbarContentBuilder
    private var autoTranslateButton: some ToolbarContent {
        ToolbarItem(placement: .secondaryAction) {
            Image(systemName: vm.autoTransaltae ? "play.circle.fill" : "stop.circle.fill")
                .foregroundColor(vm.autoTransaltae ? .accentColor : .red)
                .imageScale(.large)
                .onTapGesture {
                    vm.autoTransaltae.toggle()
                }
        }
//        Toggle("自动翻译", isOn: $vm.autoTransaltae)
//            .toggleStyle(.checkbox)
    }
    
    // MARK: 工具栏

    @ToolbarContentBuilder
    private var toolbars: some ToolbarContent {
        apiPicker
        if apiType == .deepseek {
            deepseekServiceTypePicker
        }
        if apiType == .tanshu {
            tanshuTypePicker
        }
        autoTranslateButton
        translateButton
        ToolbarItem(placement: .cancellationAction, content: {
            pinButton
        })
        ToolbarItem(placement: .cancellationAction, content: {
            Image(systemName: "gearshape")
                .onTapGesture {
                    openWindow(id: "SettingWindow")
                }
        })
    }
    
    @ToolbarContentBuilder
    private var apiPicker: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Picker("翻译API", selection: $apiType, content: {
                ForEach(APIType.allCases) { api in
                    Text(api.name)
                        .tag(api)
                }
            })
        }
    }
    
    // deepseek 服务选择
    @ToolbarContentBuilder
    private var deepseekServiceTypePicker: some ToolbarContent {
        ToolbarItem(placement: .navigation, content: {
            Picker("", selection: $vm.deepseekType, content: {
                ForEach(DeepseekServiceType.allCases, id: \.rawValue) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            })
        })
    }
    
    // 探数 API 翻译引擎选择
    @ToolbarContentBuilder
    private var tanshuTypePicker: some ToolbarContent {
        ToolbarItem(placement: .navigation, content: {
            Picker("探数翻译引擎", selection: $tanshuType) {
                ForEach(TanshuAPIType.allCases, id: \.rawValue) { api in
                    Text(api.rawValue)
                        .tag(api)
                }
            }
        })
    }
    
    // 翻译按钮
    @ToolbarContentBuilder
    private var translateButton: some ToolbarContent {
        ToolbarItem(placement: .secondaryAction) {
            if !vm.transalting {
                // 未翻译状态
                Button(action: {
                    vm.translate(api: apiType, tanshuType: tanshuType)
                }, label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                })
            } else {
                // 翻译中状态
                HStack {
                    Text("翻译中")
                        .font(.footnote)
                    Button(action: {
                        // vm.cancelTranslate()
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                    })
                }
                .foregroundColor(.red)
            }
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
            .rotationEffect(float ? .zero : .init(radians: .pi / 4))
            .animation(.spring, value: float)
            .onTapGesture {
                float.toggle()
                if let window = NSApplication.shared.windows.first {
                    window.level = float ? .floating : .normal
                }
            }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContentView()
}
