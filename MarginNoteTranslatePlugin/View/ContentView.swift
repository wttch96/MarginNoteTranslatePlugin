//
//  ContentView.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import SwiftUI
import Combine
import ApplicationServices
import AppKit

struct History: Identifiable {
    let id: String = UUID().uuidString
    let api: APIType
    let text: String
    let result: String
}

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
                        Menu(vm.from.name, content: {
                            ForEach(Language.allCases, id:\.self) { lang in
                                Button(action: {
                                    self.vm.from = lang
                                }, label: {
                                    Text(lang.name)
                                })
                            }
                        })
                        .menuStyle(BorderlessButtonMenuStyle())
                        .font(.footnote)
                        .frame(width: 40)
                        Spacer()
                        
                        if vm.concise {
                            conciseToggle
                        }
                    }
                    TextEditor(text: $vm.keywords)
                        .bold()
                        .font(.title3)
                    
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
                    HStack {
                        Text(vm.to.name)
                            .font(.footnote)
                            .bold()
                            .offset(x: 4)
                            .foregroundColor(.accentColor)
                        Menu("", content: {
                            ForEach(Language.allCases, id:\.self) { lang in
                                Button(action: {
                                    self.vm.to = lang
                                }, label: {
                                    Text(lang.name)
                                })
                            }
                        })
                        .menuStyle(BorderlessButtonMenuStyle())
                        .frame(width: 48)
                        .offset(x: -24)
                        Spacer()
                    }
                    TextEditor(text: $vm.translateResult)
                        .bold()
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    
                    
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
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                }
            }
            .textEditorStyle(.plain)
        }
        .padding(vm.concise ? 0 : 20)
        .onOpenURL(perform: self.onOpenURL)
//        .background {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(.bar)
//        }
        
        .clipShape(vm.concise ? AnyShape(RoundedRectangle(cornerRadius: 8)) : AnyShape(Rectangle()))
        .toolbar(content: {
            if !vm.concise {
                ToolbarItem( placement: .navigation,  content: {
                    historyButton
                })
                ToolbarItem(placement: .navigation) {
                    settingButton
                }
                ToolbarItem(placement: .navigation) {
                    apiPicker
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
        })
        .onAppear {
            let workspace = NSWorkspace.shared
            for app in workspace.runningApplications {
                print(getWindowsOfApplication(app))
            }
        }
        .onChange(of: vm.concise) { oldValue, newValue in
            var mask: NSWindow.StyleMask = []
            if newValue {
                // 简洁模式
                mask = [.borderless, .resizable]
                NSApplication.shared.windows.first?.backgroundColor = .clear
                NSApplication.shared.windows.first?.hasShadow = false
            } else {
                // 正常模式
                mask = [.titled, .closable, .miniaturizable, .resizable]
                
                NSApplication.shared.windows.first?.backgroundColor = .gray
            }
            NSApplication.shared.windows.first?.styleMask = mask
            NSApplication.shared.windows.first?.isMovableByWindowBackground = true
            
            NSApplication.shared.windows.first?.level = float ? .floating : .normal
        }
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
    
    private func onOpenURL(_ url: URL) {
        if let url = url.absoluteString.removingPercentEncoding {
            vm.keywords = url.replacing("WttchTranslate://keyword/", with: "")
            if vm.autoTransaltae {
                vm.translate()
            }
        }
    }
}

struct TestMyApp {
    
}


// MARK: 子视图
extension ContentView {
    // 左侧历史记录
    @ViewBuilder
    private var historyView: some View {
        ScrollView {
            VStack {
                ForEach(vm.histories.reversed(), id:\.text) { history in
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
            .rotationEffect(float ? .zero : .init(radians: .pi/4))
            .animation(.spring, value: float)
            .onTapGesture {
                float.toggle()
                if let window = NSApplication.shared.windows.first(where: { $0.title == ""}) {
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
}


#Preview {
    ContentView()
}
