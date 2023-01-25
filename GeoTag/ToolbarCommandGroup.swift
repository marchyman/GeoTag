//
//  ToolbarCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/24/23.
//

import SwiftUI

// Replace the toolbar commands group.  The command has nothing to do with a
// toolbar, but it's in the View menu which is where I want it.

extension GeoTagApp {

    var toolbarCommandGroup: some Commands {
        CommandGroup(replacing: .toolbar) {
            Button("Hide disabled Images") {
                @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false

                hideInvalidImages.toggle()
            }
                .keyboardShortcut("d")
        }
    }
}
