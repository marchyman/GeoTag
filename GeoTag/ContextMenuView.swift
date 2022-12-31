//
//  ContextMenuView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/22/22.
//

import SwiftUI

// Duplicates many of the menu commands

struct ContextMenuView: View {
    @EnvironmentObject var appState: AppState
    let context: ImageModel.ID?

    var body: some View {
        Group {
            Button("Cut") { appState.selectedMenuAction = .cut }
                .disabled(appState.cutCopyDisabled(context: context))
            Button("Copy") { appState.selectedMenuAction = .copy }
                .disabled(appState.cutCopyDisabled(context: context))
            Button("Paste") { appState.selectedMenuAction = .paste }
                .disabled(appState.pasteDisabled(context: context))
            Button("Delete") { appState.selectedMenuAction = .delete }
                .disabled(!appState.deleteDisabled(context: context))
        }
        Divider()
        Group {
            Text("Show In Finder")
            Text("Locn From Track")
            Text("Modify Date/Time")
            Text("Modify Location")
        }
        Divider()
        Button("Clear Image List") { appState.selectedMenuAction = .clearList }
            .disabled(appState.clearDisabled)
    }
}

struct ContextMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ContextMenuView(context: nil)
    }
}
