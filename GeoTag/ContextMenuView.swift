//
//  ContextMenuView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/22/22.
//

import SwiftUI

// Duplicates many of the menu commands

struct ContextMenuView: View {
    @EnvironmentObject var avm: AppViewModel
    let context: ImageModel.ID?

    var body: some View {
        Group {
            Button("Cut") { avm.cutAction(context: context) }
                .disabled(avm.cutCopyDisabled(context: context))

            Button("Copy") { avm.copyAction(context: context) }
                .disabled(avm.cutCopyDisabled(context: context))

            Button("Paste") { avm.pasteAction(context: context) }
                .disabled(avm.pasteDisabled(context: context))

            Button("Delete") { avm.deleteAction(context: context) }
                .disabled(avm.deleteDisabled(context: context))
        }

        Divider()

        Group {
            Button("Show In Finder") { avm.showInFinderAction(context: context) }
                .disabled(avm.showInFinderDisabled(context: context))

            Button("Locn From Track") { avm.locnFromTrackAction(context: context ) }
                .disabled(avm.locnFromTrackDisabled(context: context))
        }

        Divider()

        Button("Clear Image List") { avm.clearImageListAction() }
            .disabled(avm.clearDisabled)
    }
}

struct ContextMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ContextMenuView(context: nil)
    }
}
