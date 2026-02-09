import SwiftUI
import UDF

// Add a file open command in place of New...

struct NewItemCommands: Commands {
    var store: Store<GeoTagState, GeoTagEvent>

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open…") { store.send(.openCommand) }
                .keyboardShortcut("o")
        }
    }
}
