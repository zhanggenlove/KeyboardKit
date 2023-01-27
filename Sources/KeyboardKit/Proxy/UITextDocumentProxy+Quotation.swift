//
//  UITextDocumentProxy+Quotation.swift
//  KeyboardKit
//
//  Created by Daniel Saidi on 2021-03-17.
//  Copyright © 2021-2023 Daniel Saidi. All rights reserved.
//

#if os(iOS) || os(tvOS)

// MARK: - UITextDocumentProxy

import UIKit

public extension UITextDocumentProxy {

    /**
     Check whether or not the last trailing quotation before
     the input cursor is an alt. quotation begin delimiter.
     */
    func hasUnclosedAlternateQuotationBeforeInput(for locale: Locale) -> Bool {
        documentContextBeforeInput?.hasUnclosedAlternateQuotation(for: locale) ?? false
    }

    /**
     Check whether or not the last trailing quotation before
     the input cursor is a quotation begin delimiter.
     */
    func hasUnclosedQuotationBeforeInput(for locale: Locale) -> Bool {
        documentContextBeforeInput?.hasUnclosedQuotation(for: locale) ?? false
    }
}
#endif
