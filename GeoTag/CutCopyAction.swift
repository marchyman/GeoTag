//
//  CutCopyAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/31/22.
//

import AppKit

extension ViewModel {
    // return true if cut or copy actions should be disabled
    // if context is nil use selectedImage
    func cutCopyDisabled(context: ImageModel.ID? = nil) -> Bool {
        if let id = context != nil ? context : mostSelected {
            return self[id].location == nil
        }
        return true
    }

    func cutAction(context: ImageModel.ID?) {
        let id = context != nil ? context : mostSelected
        if let id {
            copyAction(context: id)
            deleteAction(context: id)
        }
    }

    func copyAction(context: ImageModel.ID?) {
        let id = context != nil ? context : mostSelected
        if let id {
            let pb = NSPasteboard.general
            pb.declareTypes([NSPasteboard.PasteboardType.string], owner: self)
            pb.setString(self[id].stringRepresentation,
                         forType: NSPasteboard.PasteboardType.string)
        }
    }
}

