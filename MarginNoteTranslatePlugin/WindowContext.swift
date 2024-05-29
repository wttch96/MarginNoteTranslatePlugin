//
//  WindowContext.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/29.
//

import Foundation
import AppKit



class WindowContext {
    public static let shared = WindowContext()
    private init() {}
    
    public func popoverWindow(_ consum: (NSWindow) -> Void) {
        if let window = IdentifiableView.findWindow(viewId: "MenuBarView") {
            consum(window)
        }
    }
    
    public func mainWindow(_ consum: (NSWindow) -> Void) {
        if let window = NSApplication.shared.windows.first(where: { $0.title.contains("MarginNote插件")}) {
            consum(window)
        }
    }
}
