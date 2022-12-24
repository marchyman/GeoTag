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

    var body: some View {
        Group {
            Button("Cut") { appState.selectedMenuAction = .cut }
                .disabled(appState.selectedIndex == nil)
            Button("Copy") { appState.selectedMenuAction = .copy }
                .disabled(appState.selectedIndex == nil)
            Button("Paste") { appState.selectedMenuAction = .paste }
                .disabled(appState.selectedIndex == nil)
            Button("Delete") { appState.selectedMenuAction = .delete }
                .disabled(appState.selectedIndex == nil)
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
            .disabled(appState.images.isEmpty)
    }
}

struct ContextMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ContextMenuView()
    }
}
