//
//  ContextMenuView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/22/22.
//

import SwiftUI

// Duplicates many of the menu commands

struct ContextMenuView: View {
    @Environment(AppState.self) var state
    let context: ImageModel?
    @AppStorage(AppSettings.extendedTimeKey) var extendedTime = 120.0

    var body: some View {
        Group {
            Button("Edit…") {
                if let context {
                    state.tvm.select(context: context)
                }
                state.inspectorPresented.toggle()
            }
            .disabled(context == nil)
        }

        Divider()

        Group {
            Button("Cut") { state.cutAction(context: context) }
                .disabled(state.cutCopyDisabled(context: context))

            Button("Copy") { state.copyAction(context: context) }
                .disabled(state.cutCopyDisabled(context: context))

            Button("Paste") { state.pasteAction(context: context) }
                .disabled(state.pasteDisabled(context: context))

            Button("Delete") { state.deleteAction(context: context) }
                .disabled(state.deleteDisabled(context: context))
        }

        Divider()

        Group {
            Button("Show In Finder") { state.showInFinderAction(context: context) }
                .disabled(state.showInFinderDisabled(context: context))

            Button("Locn From Track") {
                state.locnFromTrackAction(context: context,
                                          extendedTime: extendedTime)
            }
            .disabled(state.locnFromTrackDisabled(context: context))
        }

        Divider()

        Button("Clear Image List") { state.clearImageListAction() }
            .disabled(state.clearDisabled)
    }
}

#Preview {
    ContextMenuView(context: nil)
        .environment(AppState())
}
