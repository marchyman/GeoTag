//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import Foundation

extension AppState {

    // return true if the discard menu item should be disabled

    func discardChangesDisabled() -> Bool {
        return !isDocumentEdited
    }

    // walk through the array of images calling the revert() function
    // to put the images back in their starting state.

    func discardChangesAction() {
        for index in tvm.images.startIndex ..< tvm.images.endIndex {
            tvm.images[index].revert()
        }
        undoManager.removeAllActions()
        isDocumentEdited = false
    }
}
