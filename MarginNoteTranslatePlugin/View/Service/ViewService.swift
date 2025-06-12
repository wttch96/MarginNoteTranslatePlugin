//
//  ViewService.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2025/6/12.
//

import Foundation
import SwiftUI

protocol ViewService {
    associatedtype Content: ToolbarContent
    
    @ToolbarContentBuilder
    var secondPicker: Content { get }
}
