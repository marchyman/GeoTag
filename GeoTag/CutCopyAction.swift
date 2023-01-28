//
//  CutCopyAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/31/22.
//

import AppKit

extension AppViewModel {

    // return true if cut or copy actions should be disabled
    // if context is nil use selectedImage

    func cutCopyDisabled(context: ImageModel.ID? = nil) -> Bool {
        if let id = context != nil ? context : mostSelected {
            return self[id].location == nil
        }
        return true
    }

    // A cut is a copy followed by a delete

    func cutAction(context: ImageModel.ID? = nil) {
        copyAction(context: context)
        deleteAction(context: context)
    }

    func copyAction(context: ImageModel.ID? = nil) {
        if let context {
            selection = [context]
        }
        if let id = mostSelected {
            let pb = NSPasteboard.general
            pb.declareTypes([NSPasteboard.PasteboardType.string], owner: self)
            pb.setString(self[id].stringRepresentation,
                         forType: NSPasteboard.PasteboardType.string)
        }
    }
}

