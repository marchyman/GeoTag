//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

// Access to a view's window.  The binding to the current NSWindow is updated
// when this view is created.  To get the window make this empty view the
// background of the view who's window is desired.

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    var delegate: AppDelegate

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        Task { @MainActor in
            self.window = view.window
            self.window?.delegate = delegate
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
