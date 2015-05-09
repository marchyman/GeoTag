//
//  UnexpectedError.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/8/15.
//  Copyright (c) 2015 Marco S Hyman. All rights reserved.
//

import Cocoa

func unexpectedError(errorInfo: NSError?, _ description: String = "") {
    let alert = NSAlert()
    alert.addButtonWithTitle(NSLocalizedString("CLOSE", comment: "Close"))
    alert.messageText = NSLocalizedString("UNEXPECTED_ERROR",
                                          comment: "unexpected error")
    if let reason = errorInfo?.localizedFailureReason {
        alert.informativeText = description + reason
    } else {
        alert.informativeText = description
    }
    alert.runModal()
}