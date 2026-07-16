import OSLog
import SwiftUI
import UDF

@main
struct GeoTagApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
    @State private var store = Store(initialState: GeoTagState(),
                                     reduce: GeoTagReducer(),
                                     undoEnabled: true,
                                     didUndo: GeoTagState.didUndoRedo,
                                     didRedo: GeoTagState.didUndoRedo)

    init() {
        appDelegate.store = store
        appDelegate.logger.debug("Delegate store set")
#if DEBUG
        prepareForTesting()
#endif
    }

    var body: some Scene {
        GeoTagScene(appDelegate: appDelegate)
            .environment(store)
    }
}

// Special handling for UI testing.  Various flags may be passed to
// force the app into a specific state before running tests.

#if DEBUG
extension GeoTagApp {
    private func prepareForTesting() {
        @AppStorage(GeoTagApp.doNotBackupKey) var doNotBackup = false
        @AppStorage(GeoTagApp.savedBookmarkKey) var savedBookmark = Data()

        if CommandLine.arguments.contains("-UIINIT") {
            SettingsView.clearAllSettings()
            MapView.resetMapDefaults()
            appDelegate.logger.debug("Settings cleared")
        }
        if CommandLine.arguments.contains("-NOBACKUP") {
            doNotBackup = true
        } else if CommandLine.arguments.contains("-NOBACKUPFOLDER") {
            doNotBackup = false
            savedBookmark = Data()
        } else if CommandLine.arguments.contains("-DOBACKUP") {
            doNotBackup = false
        }
        if CommandLine.arguments.contains("-NOPLACES") {
            store.send(.clearPlaces)
        }
    }
}
#endif

// Settings keys

extension GeoTagApp {
    static let doNotBackupKey = "DoNotBackup"
    static let savedBookmarkKey = "SavedBookmark"
}

// Max number of concurrent tasks that will be fired up in any single
// task group. A number picked out of thin air.

extension GeoTagApp {
    nonisolated static let maxConcurrentTasks = 128
}
