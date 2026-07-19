import OSLog
import RunLogView
import SwiftUI
import UDF

// Extracted from GeoTagApp in an experimental attempt to fix main window
// never opens when run from XCUITesting. Will leave it this way.

struct GeoTagScene: Scene {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    @AppStorage(GeoTagApp.doNotBackupKey) var doNotBackup = false
    @AppStorage(GeoTagApp.savedBookmarkKey) var savedBookmark = Data()

    let appDelegate: AppDelegate

    @State private var mainWindow: NSWindow?

    let windowWidth = 1000.0
    let windowHeight = 700.0

    var body: some Scene {
        Window("GeoTag Version Six", id: "main") {
            ContentView()
                .background(WindowAccessor(window: $mainWindow))
                .frame(minWidth: windowWidth, minHeight: windowHeight)
                .onChange(of: mainWindow) {
                    appDelegate.logger.debug("mainWindow changed")
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
        }
        .windowResizability(.contentSize)
    }
}

// Window ids

extension GeoTagScene {
    static var adjustTimeZone = "Change Time Zone"
    static var showRunLog = "GeoTag Run/Debug Log"
}
