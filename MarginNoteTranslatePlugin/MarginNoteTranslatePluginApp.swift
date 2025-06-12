//
//  MarginNoteTranslatePluginApp.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/28.
//

import SwiftUI

@main
struct MarginNoteTranslatePluginApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate


    var body: some Scene {
        Window("MarginNote插件", id: "WttchMarginNotePlugin", content: {
            ContentView()
        })
        .windowStyle(.hiddenTitleBar)

        Window("设置", id: "SettingWindow") {
            SettingView()
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var popoverTransiencyMonitor: Any?


    func applicationDidFinishLaunching(_ notification: Notification) {
        WindowContext.shared.mainWindow { window in
//            // window.isOpaque = true
//            window.backgroundColor = .darkGray
//            // window.hasShadow = false
//            // window.level = .floating
//            // window.isMovableByWindowBackground = true
//            // window.styleMask = [.borderless]
//            // window.titleVisibility = .hidden
//            window.title = ""
//            window.titlebarAppearsTransparent = true
        }
        // 创建状态栏项目
//        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//
//        if let button = statusBarItem.button {
//            button.image = NSImage(systemSymbolName: "textformat", accessibilityDescription: "Menu Item")
//            button.action = #selector(togglePopover(_:))
//        }
//
//        popover = NSPopover()
//        popover.contentViewController = NSHostingController(rootView: MenuBarView())
//        // 去除箭头
//        popover.setValue(true, forKeyPath: "shouldHideAnchor")
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusBarItem.button {
                // 显示 popover 并居中对齐
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

                WindowContext.shared.popoverWindow { window in
                    window.hasShadow = false
                    window.backgroundColor = .clear
                    window.isOpaque = true
                }

                // 添加 transiency monitor 以自动关闭 popover
                popoverTransiencyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak self] _ in
                    self?.popover.performClose(sender)
                    if let monitor = self?.popoverTransiencyMonitor {
                        NSEvent.removeMonitor(monitor)
                        self?.popoverTransiencyMonitor = nil
                    }
                })
            }
        }
    }
}
