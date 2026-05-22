import OSLog
import RunLogView
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
    @State private var mainWindow: NSWindow?

    @AppStorage(Self.doNotBackupKey) var doNotBackup = false
    @AppStorage(Self.savedBookmarkKey) var savedBookmark = Data()

    let windowWidth = 1000.0
    let windowHeight = 700.0

    init() {
        appDelegate.store = store
        appDelegate.logger.debug("Delegate store set")
        prepareForTesting()
    }

    var body: some Scene {
        Window("GeoTag Version Six", id: "main") {
            ContentView()
                .background(WindowAccessor(window: $mainWindow))
                .frame(minWidth: windowWidth, minHeight: windowHeight)
                .onChange(of: mainWindow) {
                    appDelegate.logger.debug("mainWindow changed")
                    mainWindow?.delegate = appDelegate
                    store.send(.mainWindowChange(mainWindow), undoable: false)
                }
                .task {
                    if !doNotBackup {
                        if savedBookmark == Data() {
                            store.send(.noBackupNotice, undoable: false)
                        } else {
                            store.send(.initBackupURL, undoable: false) {
                                if store.backupURL != nil {
                                    store.send(.backupFolderSizeCheck,
                                               undoable: false)
                                }
                            }
                        }
                    }
                    let savedPlaces = await PlaceSaver.shared.read()
                    store.send(.initPlaces(savedPlaces), undoable: false)
                }
                .environment(store)

        }
        .commands {
            NewItemCommands(store: store)
            SaveItemCommands(store: store)
            UndoRedoCommands(store: store)
            PasteboardCommands(store: store)
            ToolbarCommands(store: store)
            HelpCommands(store: store)
        }

        Window(Self.adjustTimeZone, id: Self.adjustTimeZone) {
            AdjustTimezoneView()
                .frame(width: 500.0, height: 570.0)
                .environment(store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commandsRemoved()

        Window(Self.showRunLog, id: Self.showRunLog) {
            RunLogView()
                .frame(width: 700, height: 500)
        }
        .windowResizability(.contentSize)
        .commandsRemoved()

        Settings {
            SettingsView()
                .environment(store)
        }
        .windowResizability(.contentSize)

    }
}

// Window ids

extension GeoTagApp {
    static var adjustTimeZone = "Change Time Zone"
    static var showRunLog = "GeoTag Run/Debug Log"
}

// Special handling for UI testing.  Various flags may be passed to
// force the app into a specific state before running tests.

extension GeoTagApp {
    private func prepareForTesting() {
#if DEBUG
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
#endif
    }
}

// Max number of concurrent tasks that will be fired up in any single
// task group. A number picked out of thin air.

extension GeoTagApp {
    nonisolated static let maxConcurrentTasks = 128
}

// Settings keys

extension GeoTagApp {
    static let doNotBackupKey = "DoNotBackup"
    static let savedBookmarkKey = "SavedBookmark"
}
