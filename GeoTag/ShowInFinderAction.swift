//
//  ShowInFinderAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import AppKit

// Open a finder window at an images location. Image may be specified
// in context or by selection

extension AppState {

    // return true if Show In Finder menu items should be disabled.

    func showInFinderDisabled(context: ImageModel.ID? = nil) -> Bool {
        if context != nil || tvm.mostSelected != nil {
            return false
        }
        return true
    }

    // show the location on an image in a finder window.

    func showInFinderAction(context: ImageModel.ID? = nil) {
        if let context {
            tvm.select(context: context)
        }
        if let id = tvm.mostSelected?.id {
            NSWorkspace.shared.activateFileViewerSelecting([tvm[id].fileURL])
        }
    }
}
