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

    func cutAction(context: ImageModel.ID? = nil,
                   textfield: Double?? = nil) {
        if textfield == nil {
            copyAction(context: context, textfield: textfield)
            deleteAction(context: context, textfield: textfield)
        } else {
            NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
        }
    }

    func copyAction(context: ImageModel.ID? = nil,
                    textfield: Double?? = nil) {
        if textfield == nil {
            if let context {
                select(context: context)
            }
            if let id = mostSelected {
                let pb = NSPasteboard.general
                pb.declareTypes([NSPasteboard.PasteboardType.string], owner: self)
                pb.setString(self[id].stringRepresentation,
                             forType: NSPasteboard.PasteboardType.string)
            }
        } else {
            NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
        }
    }
}
