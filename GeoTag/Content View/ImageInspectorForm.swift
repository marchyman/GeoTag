//
//  ImageInspectorForm.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/10/23.
//

import SwiftUI

struct ImageInspectorForm: View {
    @Bindable var image: ImageModel
    // swiftlint:disable line_length
    let notice: LocalizedStringKey =
        "Latitude and Longitude updates will not take effect until the *return* key is pressed when either field is active."
    // swiftlint:enable line_length

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
    let image = ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1.jpg"),
                           validImage: true,
                           dateTimeCreated: "2022:12:12 11:22:33",
                           latitude: 33.123,
                           longitude: 123.456)
    return ImageInspectorForm(image: image)
        .environment(AppState())
}
