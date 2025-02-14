//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

struct ImageInspectorForm: View {
    @Bindable var image: ImageModel
    let notice: LocalizedStringKey = """
        Latitude and Longitude updates will not take effect until the \
        *return* key is pressed when either field is active.
        """

    var body: some View {
        Form {
            Section("Date and Time") {
                DateTimeSectionView(image: image)
            }
            Section("Location") {
                LatLonSectionView(image: image)
            }
            Section("Notice") {
                Text(notice)
            }
        }
    }
}

#Preview {
    let image = ImageModel(
        imageURL: URL(fileURLWithPath: "/test/path/to/image1.jpg"),
        validImage: true,
        dateTimeCreated: "2022:12:12 11:22:33",
        latitude: 33.123,
        longitude: 123.456)
    return ImageInspectorForm(image: image)
        .environment(AppState())
}
