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
            Section {
                Button {
                    vm.hideInvalidImages.toggle()
                } label: {
                    Text("\(showOrHide()) Disabled Files")
                }
                .keyboardShortcut("d")

                Button {
                    vm.onlyMostSelected.toggle()
                } label: {
                    Text(pinOption)
                }
            }

        }
    }

    private func showOrHide() -> String {
        return vm.hideInvalidImages ? "Show" : "Hide"
    }

    var pinOption: String {
        vm.onlyMostSelected
        ? "Show pins for all selected images"
        : "Show pin only for most selected image"
    }
}
