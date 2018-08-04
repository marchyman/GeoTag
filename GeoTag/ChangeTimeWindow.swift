//
//  ChangeTimeWindow.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/29/18.
//  Copyright © 2018 Marco S Hyman. All rights reserved.
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

/// Global function to open a date/time change window
///
/// - Parameter image: the image to modify
/// - Parameter callback: closure called to assign a new date/time.
///
/// The parameters are stored in the window controller where they can be
/// accessed by the date/time update view controller.

func openChangeTimeWindow(for image: ImageData,
                          _ callback: @escaping (_ dateValue: Date) -> ()) {
    let id = ChangeTimeWindowController.storyboardName
    let storyboard = NSStoryboard(name: id, bundle: nil)
    if let ctc = storyboard.instantiateInitialController() as? ChangeTimeWindowController {
        ctc.image = image
        ctc.callback = callback
        ctc.window?.makeKeyAndOrderFront(nil)
        return
    }
    unexpected(error: nil, "Cannot find ChangeTime Window")
    fatalError("Cannot find ChangeTime Window")
}

final class ChangeTimeWindowController: NSWindowController {
    static let storyboardName = NSStoryboard.Name("ChangeTime")
    weak var image: ImageData!
    var callback: ((_ dateValue: Date) -> ())? = nil

    override func windowDidLoad() {
        super.windowDidLoad()
    }
}

extension ChangeTimeWindowController: NSWindowDelegate {
    /// close the window if requested
    func windowShouldClose(sender: AnyObject!) -> Bool {
        return true
    }
}
