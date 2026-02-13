import SwiftUI
import UDF

// Replace the undoRedo commands group

struct UndoRedoCommands: Commands {
    var store: Store<GeoTagState, GeoTagEvent>

    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button(store.undoDescription) {
                store.undo()
            }
            .keyboardShortcut("z")
            .disabled(!store.canUndo)

            Button(store.redoDescription) {
                store.redo()
            }
            .keyboardShortcut("z", modifiers: [.shift, .command])
            .disabled(!store.canRedo)
        }
    }
}
