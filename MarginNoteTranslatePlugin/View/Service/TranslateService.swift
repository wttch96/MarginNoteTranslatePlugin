//
//  ViewService.swift
//  MarginNoteTranslatePlugin
//
//  Created by Wttch on 2025/6/12.
//

import Combine
import Foundation
import SwiftUI

protocol TranslateService {
    func translate(content: String)

    func close()

    var result: PassthroughSubject<(Bool, String), ApiError> { get }
}

class BaseService {
    var result = PassthroughSubject<(Bool, String), ApiError>()
}
