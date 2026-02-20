import RunLogView
import SwiftUI
import UDF

@main
struct GeoTagApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
    @State private var store = Store(initialState: GeoTagState(),
                                     reduce: GeoTagReducer(),
                                     undoEnabled: true)
    @State private var mainWindow: NSWindow?

    @AppStorage(Self.doNotBackupKey) var doNotBackup = false
    @AppStorage(Self.savedBookmarkKey) var savedBookmark = Data()

    let windowWidth = 1000.0
    let windowHeight = 700.0

    var body: some Scene {
        Window("GeoTag Version Six", id: "main") {
            ContentView()
                .background(WindowAccessor(window: $mainWindow))
                .frame(minWidth: windowWidth, minHeight: windowHeight)
                .onAppear {
                    appDelegate.store = store
                    if !doNotBackup {
                        if savedBookmark == Data() {
                            store.send(.initialBackupNotice) {
                                store.discardUndo()
                            }
                        } else {
                            store.send(.initBackupURL) {
                                store.discardUndo()
                                if store.backupURL != nil {
                                    store.send(.backupFolderSizeCheck) {
                                        store.discardUndo()
                                    }
                                }
                            }
                        }
                    }
                }
                .onChange(of: mainWindow) {
                    mainWindow?.delegate = appDelegate
                    store.send(.mainWindowChange(mainWindow)) {
                        store.discardUndo()
                    }
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

// Settings keys

extension GeoTagApp {
    static let doNotBackupKey = "DoNotBackup"
    static let savedBookmarkKey = "SavedBookmark"
}

// Text field focus. When non-nil a text field has focus.  Used to enable
// appropriate pasteboard actions for text fields.

extension FocusedValues {
    @Entry var textfieldFocused: String?
}
