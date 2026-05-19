import ImageData
import SwiftUI
import UDF

struct DateTimeSectionView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    var image: ImageData

    @State private var oldDate = Date()
    @State private var newDate = Date()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            DatePicker(
                "Old Date/Time", selection: $oldDate,
                displayedComponents: .init(rawValue: 1_234_521_450_295_224_572)
            )
            .disabled(true)
            .padding([.horizontal, .bottom])

            DatePicker(
                "New Date/Time", selection: $newDate,
                displayedComponents: .init(rawValue: 1_234_521_450_295_224_572)
            )
            .focused($isFocused)
            .padding([.horizontal, .bottom])
            .help("""
                If one image is selected it is set to this value. \
                If multiple images are selected the difference between \
                the original date/time and the updated value is \
                applied to each image.
                """
            )
        }
        .onChange(of: newDate) {
            if oldDate != newDate {
                let adjustment =
                    newDate.timeIntervalSince1970 - oldDate.timeIntervalSince1970
                store.send(.newTimestamp(newDate, adjustment))
                oldDate = newDate
            }
        }
        .onChange(of: isFocused) {
            store.send(.textfieldFocusChanged(isFocused), undoable: false)
        }
        .task(id: image) {
            oldDate = image.metadata.date(timeZone: store.timeZone)
            newDate = oldDate
        }
    }
}

 #Preview {
     Text("""
        Look at **ImageInspectorView**
        to see a preview of this sub-view
        """)
         .multilineTextAlignment(.leading)
         .padding()

 }
