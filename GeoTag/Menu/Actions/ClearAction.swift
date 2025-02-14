//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import Foundation

// Program "Clear List" action removes all images from the table

extension AppState {

    // return true if the Clear Image List menu item should be disabled

    var clearDisabled: Bool {
        tvm.images.isEmpty || isDocumentEdited
    }

    func clearImageListAction() {
        if !clearDisabled {
            stopSecurityScoping()
            tvm.selection = Set()
            tvm.images = []
        }
    }
}
