//
//  KeyboardViewController+Setup.swift
//  KeyboardKit
//
//  Created by Daniel Saidi on 2023-12-06.
//  Copyright © 2023-2025 Daniel Saidi. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(visionOS)
import SwiftUI

extension KeyboardInputViewController {
    
    /// Set up the controller for the provided app.
    func setupController(
        for app: KeyboardApp
    ) {
        KeyboardSettings.setupStore(for: app)
        state.setup(for: app)
    }
    
    /// Set up the ``Keyboard.RootView`` to present.
    func setupControllerView<Content: View>(
        _ rootView: Keyboard.RootView<Content>
    ) {
        children.forEach { $0.removeFromParent() }
        view.subviews.forEach { $0.removeFromSuperview() }
        let view = rootView.keyboardState(self.state)
        let host = KeyboardHostingController(rootView: view)
        host.add(to: self)
    }

    /// Set up the initial keyboard type.
    func setupInitialKeyboardType() {
        let context = state.keyboardContext
        guard context.keyboardType == .alphabetic else { return }
        context.syncKeyboardType(with: textDocumentProxy)
    }

    /// Set up an initial width to avoid SwiftUI layout bugs.
    func setupInitialWidth() {
        #if os(iOS) || os(tvOS)
        view.frame.size.width = UIScreen.main.bounds.width
        #else
        view.frame.size.width = 500
        #endif
    }

    /// Setup locale observation to handle locale changes.
    func setupLocaleObservation() {
        state.keyboardContext.$locale.sink { [weak self] in
            guard let self = self else { return }
            let locale = $0
            self.primaryLanguage = locale.identifier
            self.services.autocompleteService.locale = locale
        }
        .store(in: &cancellables)
    }
}
#endif
