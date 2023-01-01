//
//  ClearAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/24/22.
//

import Foundation

// Program "Clear List" action removes all images from the table

extension AppState {
    // return true if the Clear Image List meny item should be disabled
    var clearDisabled: Bool {
        images.isEmpty || (window?.isDocumentEdited ?? false)
    }

    func clearImageListAction() {
        if !clearDisabled {
            selection = Set()
            images = []
        }
    }
}
