//
//  IdentifiableView.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2024/5/29.
//

import SwiftUI

/// 定位用
struct IdentifiableView: NSViewRepresentable {
    let id: String
    
    func makeNSView(context: Context) -> some NSView {
        let view = NSView(frame: .zero)
        view.setAccessibilityIdentifier(id)
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
}


extension IdentifiableView {
    static func findWindow(viewId: String) -> NSWindow? {
        for window in NSApplication.shared.windows {
            if containViewId(view: window.contentView, viewId: viewId) {
                return window
            }
        }
        
        return nil
    }
    
    private static func containViewId(view: NSView?, viewId: String) -> Bool {
        guard let view = view else { return false }
        
        if view.accessibilityIdentifier() == viewId {
            return true
        }
        
        for subview in view.subviews {
            if containViewId(view: subview, viewId: viewId) {
                return true
            }
        }
        
        return false
    }
}

extension View {
    func viewIdentifier(_ id: String) -> some View {
        return self
            .background {
                IdentifiableView(id: id)
            }
    }
}


