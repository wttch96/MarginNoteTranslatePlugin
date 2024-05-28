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
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.level = .floating
            window.isMovableByWindowBackground = true
            window.styleMask = [.borderless]
        }
    }
}
