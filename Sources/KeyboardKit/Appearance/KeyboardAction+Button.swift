//
//  KeyboardAction+Button.swift
//  KeyboardKit
//
//  Created by Daniel Saidi on 2020-07-01.
//  Copyright © 2021 Daniel Saidi. All rights reserved.
//

import CoreGraphics
import SwiftUI

public extension KeyboardAction {
    
    /**
     The action's standard button image.
     */
    func standardButtonImage(for context: KeyboardContext) -> Image? {
        if let image = standardButtonTextImageReplacement(for: context) { return image }
        
        switch self {
        case .backspace: return .keyboardBackspace(for: context.locale)
        case .command: return .keyboardCommand
        case .control: return .keyboardControl
        case .dictation: return .keyboardDictation
        case .dismissKeyboard: return .keyboardDismiss
        case .image(_, let imageName, _): return Image(imageName)
        case .keyboardType(let type): return type.standardButtonImage
        case .moveCursorBackward: return .keyboardLeft
        case .moveCursorForward: return .keyboardRight
        case .newLine: return .keyboardNewline(for: context.locale)
        case .nextKeyboard: return .keyboardGlobe
        case .option: return .keyboardOption
        case .primary(let type): return type.standardButtonImage(for: context.locale)
        case .settings: return .keyboardSettings
        case .shift(let currentState): return currentState.standardButtonImage
        case .systemImage(_, let imageName, _): return Image(systemName: imageName)
        case .tab: return .keyboardTab
        default: return nil
        }
    }
    
    /**
     The action's standard button text.
     */
    func standardButtonText(for context: KeyboardContext) -> String? {
        switch self {
        case .character(let char): return char
        case .emoji(let emoji): return emoji.char
        case .emojiCategory(let cat): return cat.fallbackDisplayEmoji.char
        case .keyboardType(let type): return type.standardButtonText(for: context)
        case .nextLocale: return context.locale.languageCode?.uppercased()
        case .primary(let type): return type.standardButtonText(for: context.locale)
        case .return: return KKL10n.return.text(for: context)
        case .space: return KKL10n.space.text(for: context)
        default: return nil
        }
    }
    
    /**
     The action's standard button text image replacement, if
     the text represents an image asset.
     */
    func standardButtonTextImageReplacement(for context: KeyboardContext) -> Image? {
        switch standardButtonText(for: context) {
        case "↵", "↳": return .keyboardNewline(for: context.locale)
        case String.zeroWidthSpace: return .keyboardZeroWidthSpace
        default: return nil
        }
    }
}

private extension KeyboardAction.PrimaryType {
    
    func standardButtonImage(for locale: Locale) -> Image? {
        switch self {
        case .newLine: return .keyboardNewline(for: locale)
        default: return nil
        }
    }
    
    func standardButtonText(for locale: Locale) -> String? {
        switch self {
        case .done: return KKL10n.done.text(for: locale)
        case .go: return KKL10n.go.text(for: locale)
        case .newLine: return nil
        case .ok: return KKL10n.ok.text(for: locale)
        case .search: return KKL10n.search.text(for: locale)
        }
    }
}
