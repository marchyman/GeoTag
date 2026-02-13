// import MapAndSearchViews
import SwiftUI
import UDF

// Replace the pasteboard commands group

struct PasteboardCommands: Commands {
    var store: Store<GeoTagState, GeoTagEvent>

    var body: some Commands {
         CommandGroup(replacing: .pasteboard) {
            Group {
                Button("Show In Finder") {
                    store.send(.showInFinder)
                    store.discardUndo()
                }
                .disabled(store.mostSelected == nil)

                // Button("Locn From Track") {
                //     state.locnFromTrackAction(extendedTime: extendedTime) }
                //     .keyboardShortcut("l")
                    // .disabled(state.locnFromTrackDisabled())

                Button("Specify Time Zone…") {
                    store.send(.changeTimeZone)
                    store.discardUndo()
                }
            }
        }
    }
}
//     var state: AppState
//     @FocusedValue(\.textfieldFocused) var textfieldFocused
//     @AppStorage(AppSettings.extendedTimeKey) var extendedTime = 120.0
//
//     var body: some Commands {
//         CommandGroup(replacing: .pasteboard) {
//             Group {
//                 Button("Cut") {
//                     state.cutAction(textfield: isFocused(textfieldFocused))
//                 }
//                 .keyboardShortcut("x")
//                 .disabled(state.cutCopyDisabled(textfield: isFocused(textfieldFocused)))
//
//                 Button("Copy") {
//                     state.copyAction(textfield: isFocused(textfieldFocused))
//                 }
//                 .keyboardShortcut("c")
//                 .disabled(state.cutCopyDisabled(textfield: isFocused(textfieldFocused)))
//
//                 Button("Paste") {
//                     state.pasteAction(textfield: isFocused(textfieldFocused))
//                 }
//                 .keyboardShortcut("v")
//                 .disabled(state.pasteDisabled(textfield: isFocused(textfieldFocused)))
//
//                 Button("Delete") {
//                     state.deleteAction(textfield: isFocused(textfieldFocused))
//                 }
//                 .keyboardShortcut(.delete, modifiers: [])
//                 .disabled(state.deleteDisabled(textfield: isFocused(textfieldFocused)))
//
//                 Button("Select All") {
//                     state.selectAllAction(textfield: isFocused(textfieldFocused))
//                 }
//                 .keyboardShortcut("a")
//                 .disabled(state.selectAllDisabled(textfield: isFocused(textfieldFocused)))
//             }
//
//             Divider()
//
//             Group {
//                 Button("Find") {
//                     state.masData.searchBarActive = true
//                 }
//                 .keyboardShortcut("f")
//             }
//
//             Divider()
//
//             Group {
//                 Button("Show In Finder") { state.showInFinderAction() }
//                     .disabled(state.showInFinderDisabled())
//
//                 Button("Locn From Track") {
//                     state.locnFromTrackAction(extendedTime: extendedTime) }
//                     .keyboardShortcut("l")
//                     .disabled(state.locnFromTrackDisabled())
//
//                 Button("Specify Time Zone…") {
//                     state.changeTimeZoneWindow.toggle()
//                 }
//             }
//         }
//     }
//
//     // return true if a textField is focused.  That includes the search bar
//     // in the MapAndSearchViews package which can not access the
//     // textFieldFocused FocusedValue
//     private func isFocused(_ textField: String?) -> Bool {
//         return state.masData.searchBarActive || textField != nil
//     }
// }
