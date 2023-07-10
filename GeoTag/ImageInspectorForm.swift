//
//  ImageInspectorForm.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/10/23.
//

import SwiftUI

struct ImageInspectorForm: View {
    @Bindable var image: ImageModel
    @Environment(AppState.self) var state

    var body: some View {
        Form {
            Section("Date and Time") {
                Text("Date and time update goes here")
            }
            Section("Location") {
                Text("Latitude adjustments")
                Text("Longitude adjustments")
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
