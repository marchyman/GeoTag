import SwiftUI
import UDF

// Replace the undoRedo commands group

struct UndoRedoCommands: Commands {
    var store: Store<GeoTagState, GeoTagEvent>

    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button(store.textfieldActive ? "Undo" : store.undoDescription,
                   systemImage: "arrow.uturn.backward") {
                if !store.textfieldActive {
                    store.undo()
                }
            }
            .keyboardShortcut("z")
            .disabled(store.textfieldActive || !store.canUndo)

            Button(store.textfieldActive ? "Redo" : store.redoDescription,
                   systemImage: "arrow.uturn.forward") {
                if !store.textfieldActive {
                    store.redo()
                }
            }
            .keyboardShortcut("z", modifiers: [.shift, .command])
            .disabled(store.textfieldActive || !store.canRedo)
        }
    }
}
