//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import AppKit

// Open a finder window at an images location. Image may be specified
// in context or by selection

extension AppState {

    // return true if Show In Finder menu items should be disabled.

    func showInFinderDisabled(context: ImageModel? = nil) -> Bool {
        if context != nil || tvm.mostSelected != nil {
            return false
        }
        return true
    }

    // show the location on an image in a finder window.

    func showInFinderAction(context: ImageModel? = nil) {
        if let context {
            tvm.select(context: context)
        }
        if let image = tvm.mostSelected {
            NSWorkspace.shared.activateFileViewerSelecting([image.fileURL])
        }
    }
}
