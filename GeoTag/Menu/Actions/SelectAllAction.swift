//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import AppKit

extension AppState {

    func selectAllDisabled(textfield: Bool = false) -> Bool {
        if textfield {
            return false
        }
        return tvm.images.isEmpty
    }

    // when textfield is non-nil a textfield is being edited and selectAll
    // is limited to the field.  Otherwise select all items in the table.

    func selectAllAction(textfield: Bool = false) {
        if textfield {
            NSApp.sendAction(#selector(NSText.selectAll), to: nil, from: nil)
        } else {
            tvm.selection = Set(tvm.images.map { $0.id })
        }
    }
}
