//
//  SwiftUIRightClickModifier.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/23/22.
//

import SwiftUI

extension View {
    /// Adds a control click/right click handler this view (macOS only)
    ///
    /// Example
    /// ```
    /// Text("Hello")
    ///     .onRightClick { print("Right click detected") }
    /// ```
    /// - Parameters:
    ///   - handler: Block invoked when a double click is detected
    func onRightClick(handler: @escaping () -> Void) -> some View {
        modifier(RightClickHandler(handler: handler))
    }
}

struct RightClickHandler: ViewModifier {
    let handler: () -> Void
    func body(content: Content) -> some View {
        content.overlay {
            RightClickListeningViewRepresentable(handler: handler)
        }
    }
}

struct RightClickListeningViewRepresentable: NSViewRepresentable {
    let handler: () -> Void
    func makeNSView(context: Context) -> RightClickListeningView {
        RightClickListeningView(handler: handler)
    }
    func updateNSView(_ nsView: RightClickListeningView, context: Context) {}
}

class RightClickListeningView: NSView {
    let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func rightMouseDown(with theEvent: NSEvent) {
        handler()
        super.rightMouseDown(with: theEvent)
    }
}
