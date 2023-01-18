//
//  ContextMenuView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/22/22.
//

import SwiftUI

// Duplicates many of the menu commands

struct ContextMenuView: View {
    @EnvironmentObject var vm: ViewModel
    let context: ImageModel.ID?

    var body: some View {
        Group {
            Button("Cut") { setContextMenuAction(.cut) }
                .disabled(vm.cutCopyDisabled(context: context))

            Button("Copy") { setContextMenuAction(.copy) }
                .disabled(vm.cutCopyDisabled(context: context))

            Button("Paste") { setContextMenuAction(.paste) }
                .disabled(vm.pasteDisabled(context: context))

            Button("Delete") { setContextMenuAction(.delete) }
                .disabled(vm.deleteDisabled(context: context))
        }
        
        Divider()

        Group {
            Button("Show In Finder") { setContextMenuAction(.showInFinder) }
                .disabled(vm.showInFinderDisabled(context: context))

            Button("Locn From Track") { setContextMenuAction(.locnFromTrack) }
                .disabled(vm.locnFromTrackDisabled(context: context))
        }

        Divider()

        Button("Clear Image List") { setContextMenuAction(.clearList) }
            .disabled(vm.clearDisabled)
    }

    func setContextMenuAction(_ action: ViewModel.MenuAction) {
        vm.setMenuAction(for: action, context: context)
    }
}

struct ContextMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ContextMenuView(context: nil)
    }
}