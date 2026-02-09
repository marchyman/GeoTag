// import AdjustTimeZoneView
import RunLogView
import SwiftUI
import UDF

@main
struct GeoTagApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
    @State private var store = Store(initialState: GeoTagState(),
                                     reduce: GeoTagReducer())
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
                    if !doNotBackup && savedBookmark == Data() {
                        store.send(.initialBackupCheck)
                    }
                }
                .onChange(of: mainWindow) {
                    mainWindow?.delegate = appDelegate
                    store.send(.mainWindowChange(mainWindow))
                }
                .environment(store)

        }
        .commands {
            NewItemCommands(store: store)
        //     SaveItemCommands(state: state)
        //     UndoRedoCommands(state: state)
        //     PasteboardCommands(state: state)
        //     ToolbarCommands(state: state)
            HelpCommands(store: store)
        }

        // Window(GeoTagApp.adjustTimeZone, id: Self.adjustTimeZone) {
        //     AdjustTimezoneView(timeZone: $state.timeZone)
        //         .frame(width: 500.0, height: 570.0)
        //         .environment(state)
        // }
        // .windowStyle(.hiddenTitleBar)
        // .windowResizability(.contentSize)
        // .commandsRemoved()
        //
        Window(Self.showRunLog, id: Self.showRunLog) {
            RunLogView()
                .frame(width: 700, height: 500)
        }
        .windowResizability(.contentSize)
        .commandsRemoved()
        //
        // Settings {
        //     SettingsView()
        //         .environment(state)
        // }
        // .windowResizability(.contentSize)

    }
}

// Window ids

extension GeoTagApp {
    static var adjustTimeZone = "Change Time Zone"
    static var showRunLog = "GeoTag Run/Debug Log"
}

// AppSettings keys

extension GeoTagApp {
    static let doNotBackupKey = "DoNotBackup"
    static let savedBookmarkKey = "SavedBookmark"
}

// Text field focus. When non-nil a text field has focus.  Used to enable
// appropriate pasteboard actions for text fields.

extension FocusedValues {
    @Entry var textfieldFocused: String?
}
