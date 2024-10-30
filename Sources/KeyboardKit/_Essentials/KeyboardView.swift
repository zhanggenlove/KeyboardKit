//
//  KeyboardView.swift
//  KeyboardKit
//
//  Created by Daniel Saidi on 2020-12-02.
//  Copyright © 2020-2024 Daniel Saidi. All rights reserved.
//

import SwiftUI

/// This view can be used to mimic a native iOS keyboard.
///
/// This view can render any ``KeyboardLayout`` and supports
/// alphabetic, numeric and symbolic keyboard types, as well
/// as any custom layout you may specify.
///
/// KeyboardKit will by default use this as the default view.
/// So, if you only want to use a standard keyboard view and
/// use the ``KeyboardInputViewController/state`` properties
/// and the ``KeyboardInputViewController/services`` service
/// instances to customize it, you don't have to do anything.
///
/// See the <doc:Essentials-Article> article for more information on
/// how you can customize this and other system views.
public struct KeyboardView<
    ButtonContent: View,
    ButtonView: View,
    EmojiKeyboard: View,
    Toolbar: View>: KeyboardViewComponent {

    /// Create a keyboard based on state and services.
    ///
    /// - Parameters:
    ///   - layout: A custom keyboard layout, if any.
    ///   - state: The keyboard state to use.
    ///   - services: The keyboard services to use.
    ///   - renderBackground: Whether to render the background.
    ///   - buttonContent: The content view to use for buttons.
    ///   - buttonView: The button view to use for an buttons.
    ///   - emojiKeyboard: The emoji keyboard to use for an ``Keyboard/KeyboardType/emojis`` keyboard.
    ///   - toolbar: The toolbar view to add above the keyboard.
    public init(
        layout: KeyboardLayout? = nil,
        state: Keyboard.State,
        services: Keyboard.Services,
        renderBackground: Bool = true,
        @ViewBuilder buttonContent: @escaping ButtonContentBuilder,
        @ViewBuilder buttonView: @escaping ButtonViewBuilder,
        @ViewBuilder emojiKeyboard: @escaping EmojiKeyboardBuilder,
        @ViewBuilder toolbar: @escaping ToolbarBuilder
    ) {
        let serviceLayout = services.layoutService
            .keyboardLayout(for: state.keyboardContext)
        self.init(
            layout: layout ?? serviceLayout,
            actionHandler: services.actionHandler,
            repeatTimer: services.repeatGestureTimer,
            styleService: services.styleService,
            keyboardContext: state.keyboardContext,
            autocompleteContext: state.autocompleteContext,
            calloutContext: state.calloutContext,
            renderBackground: renderBackground,
            buttonContent: buttonContent,
            buttonView: buttonView,
            emojiKeyboard: emojiKeyboard,
            toolbar: toolbar
        )
    }
    
    /// Create a keyboard based on raw properties.
    ///
    /// - Parameters:
    ///   - layout: The layout to use.
    ///   - actionHandler: The action handler to use.
    ///   - repeatTimer: The repeat gesture timer to use, if any.
    ///   - styleService: The style service to use.
    ///   - keyboardContext: The keyboard context to use.
    ///   - autocompleteContext: The autocomplete context to use.
    ///   - calloutContext: The callout context to use.
    ///   - renderBackground: Whether to render the background, by default `true`.
    ///   - buttonContent: The content view to use for buttons.
    ///   - buttonView: The button view to use for an buttons.
    ///   - emojiKeyboard: The emoji keyboard to use for an ``Keyboard/KeyboardType/emojis`` keyboard.
    ///   - toolbar: The toolbar view to add above the keyboard.
    public init(
        layout: KeyboardLayout,
        actionHandler: KeyboardActionHandler,
        repeatTimer: GestureButtonTimer? = nil,
        styleService: KeyboardStyleService,
        keyboardContext: KeyboardContext,
        autocompleteContext: AutocompleteContext,
        calloutContext: CalloutContext?,
        renderBackground: Bool = true,
        @ViewBuilder buttonContent: @escaping ButtonContentBuilder,
        @ViewBuilder buttonView: @escaping ButtonViewBuilder,
        @ViewBuilder emojiKeyboard: @escaping EmojiKeyboardBuilder,
        @ViewBuilder toolbar: @escaping ToolbarBuilder
    ) {
        var layout = layout
        let layoutConfig = KeyboardLayout.Configuration.standard(for: keyboardContext)
        if !Emoji.KeyboardWrapper.isEmojiKeyboardAvailable {
            layout.itemRows.remove(.keyboardType(.emojis))
        }
        self.rawLayout = layout
        self.layoutConfig = layoutConfig
        self.actionHandler = actionHandler
        self.repeatTimer = repeatTimer
        self.styleService = styleService
        self.renderBackground = renderBackground
        self.buttonContentBuilder = buttonContent
        self.buttonViewBuilder = buttonView
        self.emojiKeyboardBuilder = emojiKeyboard
        self.toolbarBuilder = toolbar

        _autocompleteContext = ObservedObject(wrappedValue: autocompleteContext)
        _calloutContext = ObservedObject(wrappedValue: calloutContext ?? .disabled)
        _keyboardContext = ObservedObject(wrappedValue: keyboardContext)

        self.actionCalloutStyle = {
            var style = styleService.actionCalloutStyle
            let insets = layoutConfig.buttonInsets
            style.callout.buttonInset = CGSize(width: insets.leading, height: insets.top)
            return style
        }()

        self.inputCalloutStyle = {
            var style = styleService.inputCalloutStyle
            let insets = layoutConfig.buttonInsets
            style.callout.buttonInset = CGSize(width: insets.leading, height: insets.top)
            return style
        }()
    }

    private let actionHandler: KeyboardActionHandler
    private let repeatTimer: GestureButtonTimer?
    private let rawLayout: KeyboardLayout
    private let layoutConfig: KeyboardLayout.Configuration
    private let styleService: KeyboardStyleService
    private let renderBackground: Bool
    
    private let buttonContentBuilder: ButtonContentBuilder
    private let buttonViewBuilder: ButtonViewBuilder
    private let emojiKeyboardBuilder: EmojiKeyboardBuilder
    private let toolbarBuilder: ToolbarBuilder
    
    private var actionCalloutStyle: Callouts.ActionCalloutStyle
    private var inputCalloutStyle: Callouts.InputCalloutStyle

    @ObservedObject
    private var autocompleteContext: AutocompleteContext

    @ObservedObject
    private var calloutContext: CalloutContext

    @ObservedObject
    private var keyboardContext: KeyboardContext
    
    @Environment(\.keyboardInputToolbarDisplayMode)
    private var rawInputToolbarDisplayMode

    public var body: some View {
        KeyboardStyle.StandardService.iPadProRenderingModeActive = layout.ipadProLayout

        return VStack(spacing: 0) {
            toolbar
            keyboardView
        }
        .autocorrectionDisabled(with: autocompleteContext)
        .opacity(shouldShowKeyboard ? 1 : 0)
        .overlay(emojiKeyboard, alignment: .bottom)
        .overlay(numberPad, alignment: .bottom)
        .foregroundColor(styleService.foregroundColor)
        .background(renderBackground ? styleService.backgroundStyle : nil)
        .keyboardCalloutContainer(
            calloutContext: calloutContext,
            keyboardContext: keyboardContext
        )
        .actionCalloutStyle(actionCalloutStyle)
        .inputCalloutStyle(inputCalloutStyle)
    }
}

public extension KeyboardView {

    /// This typealias defines an emoji keyboard builder.
    typealias EmojiKeyboardBuilder = (EmojiKeyboardParams) -> EmojiKeyboard

    /// This typealias defines emoji keyboard builder params.
    typealias EmojiKeyboardParams = (
        style: Emoji.KeyboardStyle,
        view: StandardEmojiKeyboard)

    /// This typealias defines a toolbar builder.
    typealias ToolbarBuilder = (ToolbarParams) -> Toolbar

    /// This typealias defines toolbar builder params.
    typealias ToolbarParams = (
        autocompleteAction: (Autocomplete.Suggestion) -> Void,
        style: Autocomplete.ToolbarStyle,
        view: StandardToolbarView)
}

public extension KeyboardView {

    /// The standard emoji keyboard view.
    typealias StandardEmojiKeyboard = Emoji.KeyboardWrapper

    /// The standard toolbar view.
    typealias StandardToolbarView = Autocomplete.Toolbar<Autocomplete.ToolbarItem, Autocomplete.ToolbarSeparator>
}

private extension KeyboardView {

    var isLargePad: Bool {
        let size = keyboardContext.screenSize
        return size.isScreenSize(.iPadProLargeScreenPortrait, withTolerance: 50)
    }

    var inputToolbarDisplayMode: Keyboard.InputToolbarDisplayMode {
        switch rawInputToolbarDisplayMode {
        case .automatic: isLargePad ? .numbers : .hidden
        default: rawInputToolbarDisplayMode
        }
    }

    var layout: KeyboardLayout {
        rawLayout.adjusted(
            for: inputToolbarDisplayMode,
            layoutConfiguration: layoutConfig
        )
    }

    var shouldShowKeyboard: Bool {
        switch keyboardContext.keyboardType {
        case .emojis: false
        case .numberPad: false
        default: true
        }
    }

    var shouldShowEmojiKeyboard: Bool {
        switch keyboardContext.keyboardType {
        case .emojis: true
        case .emojiSearch: true
        default: false
        }
    }

    var shouldShowToolbar: Bool {
        switch keyboardContext.keyboardType {
        case .emojiSearch: false
        default: true
        }
    }
}

private extension KeyboardView {

    var keyboardView: some View {
        GeometryReader { geo in
            let inputWidth = layout.inputWidth(for: geo.size.width)
            VStack(spacing: 0) {
                ForEach(Array(layout.itemRows.enumerated()), id: \.offset) { row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.element.enumerated()), id: \.offset) { item in
                            buttonView(
                                for: item.element,
                                totalWidth: geo.size.width,
                                inputWidth: inputWidth
                            )
                        }
                    }
                }
            }
            .padding(styleService.keyboardEdgeInsets)
            .environment(\.layoutDirection, .leftToRight)   // Enforce a direction due to the layout.
        }
        .frame(height: layout.totalHeight)
    }
    
    @ViewBuilder
    var emojiKeyboard: some View {
        emojiKeyboardContent
            .id(keyboardContext.interfaceOrientation)       // TODO: Temp orientation fix, still needed?
    }

    @ViewBuilder
    var emojiKeyboardContent: some View {
        if shouldShowEmojiKeyboard {                        // Conditional to save memory
            emojiKeyboardBuilder((
                style: Emoji.KeyboardStyle.standard(for: keyboardContext),
                view: Emoji.KeyboardWrapper(
                    actionHandler: actionHandler,
                    keyboardContext: keyboardContext,
                    calloutContext: calloutContext,
                    styleService: styleService
                )
            ))
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    var numberPad: some View {
        if keyboardContext.keyboardType == .numberPad {
            Keyboard.NumberPad(
                actionHandler: actionHandler,
                styleService: styleService,
                keyboardContext: keyboardContext
            )
            .padding(10)
        }
    }

    var toolbar: some View {
        let style = styleService.autocompleteToolbarStyle
        return toolbarBuilder((
            autocompleteAction: actionHandler.handle(_:),
            style: styleService.autocompleteToolbarStyle,
            view: Autocomplete.Toolbar(
                suggestions: autocompleteContext.suggestions,
                itemView: { $0.view },
                separatorView: { $0.view },
                suggestionAction: actionHandler.handle(_:)
            )
        ))
        .opacity(shouldShowToolbar ? 1 : 0)
        .autocompleteToolbarStyle(style)
        .frame(minHeight: style.height)
    }
}

private extension KeyboardView {

    func buttonContent(
        for item: KeyboardLayout.Item
    ) -> ButtonContent {
        buttonContentBuilder((
            item: item,
            view: Keyboard.ButtonContent(
                action: item.action,
                styleService: styleService,
                keyboardContext: keyboardContext
            )
        ))
    }
    
    func buttonView(
        for item: KeyboardLayout.Item,
        totalWidth width: Double,
        inputWidth: Double
    ) -> ButtonView {
        let action = item.action
        let prediction = autocompleteContext.nextCharacterPrediction(for: action)
        return buttonViewBuilder((
            item: item,
            view: KeyboardViewItem(
                item: item,
                actionHandler: actionHandler,
                repeatTimer: repeatTimer,
                styleService: styleService,
                keyboardContext: keyboardContext,
                calloutContext: calloutContext,
                keyboardWidth: width,
                inputWidth: inputWidth,
                isNextProbability: prediction,
                content: buttonContent(for: item)
            )
        ))
    }
}


#if os(iOS) || os(tvOS) || os(visionOS)
#Preview {

    struct Preview: View {

        var controller: KeyboardInputViewController = {
            let controller = KeyboardInputViewController.preview
            controller.state.autocompleteContext.suggestions = [
                .init(text: "Foo"),
                .init(text: "Bar", type: .autocorrect),
                .init(text: "Baz")
            ]
            // controller.services.styleService = .crazy
            // controller.state.keyboardContext.keyboardType = .emojiSearch
            return controller
        }()
        
        var keyboard: some View {
            KeyboardView(
                state: controller.state,
                services: controller.services,
                renderBackground: true,
                buttonContent: { $0.view },
                buttonView: { $0.view },
                emojiKeyboard: { $0.view },
                toolbar: { $0.view }
            )
        }

        var body: some View {
            ScrollView {
                VStack(spacing: 10) {
                    Group {
                        keyboard
                        
                        keyboard.frame(width: 250)
                        
                        KeyboardView(
                            layout: controller.services
                                .layoutService
                                .keyboardLayout(for: .preview)
                                .bottomRowLayout,
                            state: controller.state,
                            services: controller.services,
                            buttonContent: { $0.view },
                            buttonView: { $0.view },
                            emojiKeyboard: { $0.view },
                            toolbar: { _ in EmptyView() }
                        )
                        
                        KeyboardView(
                            state: controller.state,
                            services: controller.services,
                            buttonContent: { param in
                                switch param.item.action {
                                case .backspace:
                                    Image(systemName: "trash").foregroundColor(Color.red)
                                default: param.view
                                }
                            },
                            buttonView: { param in
                                switch param.item.action {
                                case .space:
                                    Text("This is a space bar replacement")
                                        .frame(maxWidth: .infinity)
                                        .multilineTextAlignment(.center)
                                default: param.view
                                }
                            },
                            emojiKeyboard: { _ in
                                Button {
                                    controller.state.keyboardContext.keyboardType = .alphabetic
                                } label: {
                                    Color.red
                                        .overlay(Text("Not implemented"))
                                }
                            },
                            toolbar: { $0.view }
                        )
                    }
                    .background(Color.keyboardBackground)
                    .keyboardInputToolbarDisplayMode(.numbers)
                }
            }
        }
    }

    return Preview()
}
#endif
