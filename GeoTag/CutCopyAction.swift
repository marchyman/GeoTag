//
//  CutCopyAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/31/22.
//

import AppKit

extension AppState {

    // return true if cut or copy actions should be disabled
    // if context is nil use selectedImage

    func cutCopyDisabled(context: ImageModel? = nil) -> Bool {
        if let image = context {
            return image.location == nil
        }
        return tvm.mostSelected == nil
    }

    // A cut is a copy followed by a delete

    func cutAction(context: ImageModel? = nil,
                   textfield: Bool?? = nil) {
        if textfield == nil {
            copyAction(context: context, textfield: textfield)
            deleteAction(context: context, textfield: textfield)
        } else {
            NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
        }
    }

    func copyAction(context: ImageModel? = nil,
                    textfield: Bool?? = nil) {
        if textfield == nil {
            if let context {
                tvm.select(context: context)
            }
            if let image = tvm.mostSelected {
                let pb = NSPasteboard.general
                pb.declareTypes([NSPasteboard.PasteboardType.string], owner: self)
                pb.setString(image.stringRepresentation,
                             forType: NSPasteboard.PasteboardType.string)
            }
        } else {
            NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
        }
    }
}
