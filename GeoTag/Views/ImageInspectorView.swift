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

#Preview(traits: .select(11)) {
    Text("some view")
        .inspector(isPresented: .constant(true)) {
            ImageInspectorView()
                .inspectorColumnWidth(400)
        }
        .frame(height: 1000)
}
