import ImageData
import SwiftUI
import UDF

// show an inspector to modify image metadata if not nil

struct ImageInspectorView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    var body: some View {
        if let imageID = store.mostSelected {
            ImageInspectorForm(image: store[imageID])
        } else {
            ContentUnavailableView {
                Image(systemName: "magnifyingglass.circle")
            } description: {
                Text("Please select an image")
            }
        }
    }
}

// TODO
// #Preview {
//     ImageInspectorView()
//         .environment(AppState())
// }
