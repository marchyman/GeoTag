import ImageData
import SwiftUI
import UDF

struct ImageInspectorForm: View {
    var image: ImageData
    let notice: LocalizedStringKey = """
        Latitude and Longitude updates will not take effect until the \
        *return* key is pressed when either field is active.
        """

    var body: some View {
        Text("ImageInspectorForm here")
        // Form {
        //     Section("Date and Time") {
        //         DateTimeSectionView(image: image)
        //     }
        //     Section("Location") {
        //         LatLonSectionView(image: image)
        //     }
        //     Section("Notice") {
        //         Text(notice)
        //     }
        // }
    }
}

// #Preview {
//     let image = ImageModel(
//         imageURL: URL(fileURLWithPath: "/test/path/to/image1.jpg"),
//         validImage: true,
//         dateTimeCreated: "2022:12:12 11:22:33",
//         latitude: 33.123,
//         longitude: 123.456)
//     Text("Inspector")
//         .inspector(isPresented: .constant(true)) {
//             ImageInspectorForm(image: image)
//                 .inspectorColumnWidth(400)
//         }
//         .frame(width: 600, height: 800)
//         .environment(AppState())
// }
