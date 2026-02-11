import SwiftUI
import UDF

struct RemoveBackupsAlert: ViewModifier {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
    @State private var removeBackups = false

    func body(content: Content) -> some View {
        content
            .alert("Delete old backup files?", isPresented: $removeBackups) {
                Button("Delete", role: .destructive) {
                    store.send(.removeOldFiles)
                }
                Button("Cancel", role: .cancel) {}
                    .keyboardShortcut(.defaultAction)
            } message: {
                Text("""
                    Your current backup/save folder

                        \(store.backupURL != nil ? store.backupURL!.path : "unknown")

                    is using \(store.folderSize / 1_000_000) MB to store backup files.

                    \(store.oldFiles.count) files using \
                    \(store.deletedSize / 1_000_000) MB of storage were \
                    placed in the folder more than 7 days ago.

                    Would you like to remove those \(store.oldFiles.count) backup files?
                    """)
            }
        .onChange(of: store.oldFiles) {
            removeBackups = !store.oldFiles.isEmpty
        }
        .task {
            removeBackups = !store.oldFiles.isEmpty
        }
    }
}

extension View {
    func removeBackupsAlert() -> some View {
        modifier(RemoveBackupsAlert())
    }
}
