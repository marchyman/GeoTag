//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

struct RemoveBackupsAlert: ViewModifier {
    @Environment(AppState.self) var state

    func body(content: Content) -> some View {
        @Bindable var state = state
        content
            .alert("Delete old backup files?", isPresented: $state.removeOldFiles) {
                Button("Delete", role: .destructive) {
                    state.remove(filesToRemove: state.oldFiles)
                }
                Button("Cancel", role: .cancel) {}
                    .keyboardShortcut(.defaultAction)
            } message: {
                Text(
                    """
                    Your current backup/save folder

                        \(state.backupURL != nil ? state.backupURL!.path : "unknown")

                    is using \(state.folderSize / 1_000_000) MB to store backup files.

                    \(state.oldFiles.count) files using \
                    \(state.deletedSize / 1_000_000) MB of storage were \
                    placed in the folder more than 7 days ago.

                    Would you like to remove those \(state.oldFiles.count) backup files?
                    """)
            }
    }
}

extension View {
    func removeBackupsAlert() -> some View {
        modifier(RemoveBackupsAlert())
    }
}
