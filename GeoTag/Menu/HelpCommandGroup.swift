import SwiftUI
import UDF

// Add a help button that will link to the on line help pages.

struct HelpCommands: Commands {
    var store: Store<GeoTagState, GeoTagEvent>

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Link(destination: URL(string: "https://www.snafu.org/GeoTag/GeoTag5Help/")!) {
                 Label("GeoTag 5 Help…", systemImage: "link")
            }
            Divider()
            Link(destination: URL(string: "https://github.com/marchyman/GeoTag/issues")!) {
                Label("Report a bug…", systemImage: "link")
            }
            Button("Show log…", systemImage: "list.clipboard") {
                store.send(.toggleLogWindow) {
                    store.discardUndo()
                }
            }
        }
    }
}
