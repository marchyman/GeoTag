//
//  ContextMenuView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/22/22.
//

import SwiftUI

// Duplicates many of the menu commands

struct ContextMenuView: View {
    @EnvironmentObject var vm: AppViewModel
    let context: ImageModel.ID?

    var body: some View {
        Group {
            Button("Cut") { vm.cutAction(context: context) }
                .disabled(vm.cutCopyDisabled(context: context))

            Button("Copy") { vm.copyAction(context: context) }
                .disabled(vm.cutCopyDisabled(context: context))

            Button("Paste") { vm.pasteAction(context: context) }
                .disabled(vm.pasteDisabled(context: context))

            Button("Delete") { vm.deleteAction(context: context) }
                .disabled(vm.deleteDisabled(context: context))
        }
        
        Divider()

        Group {
            Button("Show In Finder") { vm.showInFinderAction(context: context) }
                .disabled(vm.showInFinderDisabled(context: context))

            Button("Locn From Track") { vm.locnFromTrackAction(context: context ) }
                .disabled(vm.locnFromTrackDisabled(context: context))
        }

        Divider()

        Button("Clear Image List") { vm.clearImageListAction() }
            .disabled(vm.clearDisabled)
    }
}

struct ContextMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ContextMenuView(context: nil)
    }
}
