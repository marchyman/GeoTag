//
//  ChangeTimeWindow.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/29/18.
//  Copyright © 2018 Marco S Hyman. All rights reserved.
//

import Foundation
import AppKit

func openChangeTimeWindow(
    for image: ImageData,
    _ callback: @escaping () -> ()
) {
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
    var callback: (() -> ())? = nil

    override func windowDidLoad() {
        super.windowDidLoad()
    }
}

extension ChangeTimeWindowController: NSWindowDelegate {
    /// close the window if requested
    func windowShouldClose(
        sender: AnyObject!
    ) -> Bool {
        return true
    }
}
