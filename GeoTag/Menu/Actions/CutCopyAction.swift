//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import AppKit

extension AppState {

    // return true if cut or copy actions should be disabled
    // if context is nil use selectedImage

    func cutCopyDisabled(
        context: ImageModel? = nil,
        textfield: Bool = false
    ) -> Bool {
        if textfield {
            return false
        }
        if let image = context {
            return image.location == nil
        }
        return tvm.mostSelected?.location == nil
    }

    // A cut is a copy followed by a delete

    func cutAction(
        context: ImageModel? = nil,
        textfield: Bool = false
    ) {
        if textfield {
            NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
        } else {
            copyAction(context: context, textfield: textfield)
            deleteAction(context: context, textfield: textfield)
        }
    }

    func copyAction(
        context: ImageModel? = nil,
        textfield: Bool = false
    ) {
        if textfield {
            NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
        } else {
            if let context {
                tvm.select(context: context)
            }
            if let image = tvm.mostSelected {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(image.stringRepresentation, forType: .string)
            }
        }
    }
}
