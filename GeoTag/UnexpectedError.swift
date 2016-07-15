//
//  UnexpectedError.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/8/15.
//  Copyright (c) 2015 Marco S Hyman, CC-BY-NC
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

public func unexpected(error: NSError?, _ description: String = "") {
    let alert = NSAlert()
    alert.addButton(withTitle: NSLocalizedString("CLOSE", comment: "Close"))
    alert.messageText = NSLocalizedString("UNEXPECTED_ERROR",
                                          comment: "unexpected error")
    if let reason = error?.localizedFailureReason {
        alert.informativeText = description + reason
    } else {
        alert.informativeText = description
    }
    alert.runModal()
}
