//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

// Add a file open command in place of New...

struct NewItemCommands: Commands {
    var state: AppState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open…") { state.importFiles = true }
                .keyboardShortcut("o")
        }
    }
}
