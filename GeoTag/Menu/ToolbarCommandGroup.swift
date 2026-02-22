// import MapAndSearchViews
import SwiftUI
import UDF

// Replace the toolbar commands group.  The command has nothing to do with a
// toolbar, but it's in the View menu which is where I want it.

struct ToolbarCommands: Commands {
    var store: Store<GeoTagState, GeoTagEvent>

    var body: some Commands {
        CommandGroup(replacing: .toolbar) {
            Section {
                Button {
                    @AppStorage(ImageTableView.hideInvalidImagesKey) var hideInvalidImages = false

                    hideInvalidImages.toggle()
                } label: {
                    ShowHidePinView()
                }
                .keyboardShortcut("d")

                PinOptionView()

                Button {
                    @AppStorage(ContentView.alternateLayoutKey) var alternateLayout = false

                    alternateLayout.toggle()
                } label: {
                    AlternateLayoutOptionView()
                }
            }

        }
    }
}

struct ShowHidePinView: View {
    @AppStorage(ImageTableView.hideInvalidImagesKey) var hideInvalidImages = false

    var body: some View {
        if hideInvalidImages {
            Label("Show Disabled Files", systemImage: "eye")
        } else {
            Label("Hide Disabled Files", systemImage: "eye.slash")
        }
    }
}

struct PinOptionView: View {
    @AppStorage(MapView.showOtherPinsKey) var showOtherPins = false

    var body: some View {
        Picker(selection: $showOtherPins) {
            Text("Show pins for all selected items").tag(true)
            Text("Show pin for most selected item").tag(false)
        } label: {
            Label("Pin view options…", systemImage: "mappin.circle")
        }
        .pickerStyle(.menu)
    }
}

struct AlternateLayoutOptionView: View {
    @AppStorage(ContentView.alternateLayoutKey) var alternateLayout = false

    var body: some View {
        Label("\(alternateLayout ? "Normal" : "Alternate") Layout",
              systemImage: "arrow.left.arrow.right.square")
    }
}
