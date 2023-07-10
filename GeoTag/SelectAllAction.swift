//
//  SelectAllAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/16/23.
//

import AppKit

extension AppState {

    func selectAllDisabled() -> Bool {
        return tvm.images.isEmpty
    }

    // when textfield is non-nil a textfield is being edited and selectAll
    // is limited to the field.  Otherwise select all items in the table.

    func selectAllAction(textfield: Double??) {
        if textfield == nil {
            tvm.selection = Set(tvm.images.map { $0.id })
        } else {
            NSApp.sendAction(#selector(NSText.selectAll), to: nil, from: nil)
        }
    }
}
