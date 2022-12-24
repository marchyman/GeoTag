//
//  UnexpectedError.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/8/15.
//  Copyright 2015-2018 Marco S Hyman
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

    /// display an alert indicating some unexpected error occurred
    /// - Parameter errorInfo: An NSError? often obtained from some framework call.
    /// - Parameter description: A string describing the issue with an empty default value.
    ///
    /// Show a modal alert telling the user that something unexpected happened.
    /// If errorInfo is not nil the system error description will be appended to the
    /// programmer provided description string.

public
func unexpected(error: NSError?,
                _ description: String = "") {
    let alert = NSAlert()
    alert.addButton(withTitle: NSLocalizedString("CLOSE", comment: "Close"))
    alert.messageText = NSLocalizedString("UNEXPECTED_ERROR",
                                          comment: "unexpected error")
    if let reason = error?.localizedDescription {
        alert.informativeText = description + reason
    } else {
        alert.informativeText = description
    }
    alert.runModal()
}
