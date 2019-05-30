//
//  PreferencesWindow.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/7/15.
//  Copyright 2019 Marco S Hyman
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import AppKit

// MARK: Preferences Window Controller

func openPreferencesWindow() {
    let id = PreferencesWindowController.storyboardName
    let storyboard = NSStoryboard(name: id, bundle: nil)
    if let pc = storyboard.instantiateInitialController() as? PreferencesWindowController {
        pc.window?.makeKeyAndOrderFront(nil)
        return
    }
    unexpected(error: nil, "Cannot find Preferences Window")
    fatalError("Cannot find Preferences Window")
}

final class PreferencesWindowController: NSWindowController {
    static let storyboardName = NSStoryboard.Name("Preferences")
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
}

extension PreferencesWindowController: NSWindowDelegate {
    /// hide the window, it may be needed again
    func windowShouldClose(sender: AnyObject!) -> Bool {
        return true
    }
}
