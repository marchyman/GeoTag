//
//  PasteAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/31/22.
//

import Foundation

// "Paste" into all selected images or a specific image in context
// selected images

extension ViewModel {
    // return true if paste actions should be disabled
    // if context is nil use selectedImage
    func pasteDisabled(context: ImageModel.ID? = nil) -> Bool {
        // checl pasteboard, too
        if context != nil || mostSelected != nil {
            return false
        }
        return true
    }

    func pasteAction(context: ImageModel.ID? = nil) {
        // UNDO here
        // handle context paste and selection paste
    }
}
