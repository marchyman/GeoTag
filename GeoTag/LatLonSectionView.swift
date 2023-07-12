//
//  LatLonSectionView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/12/23.
//

import SwiftUI

struct LatLonSectionView: View {
    @Bindable var image: ImageModel
    @Environment(AppState.self) var state
    @FocusState private var isFocused: Bool

    var body: some View {
        Text("Latitude adjustments")
        Text("Longitude adjustments")
    }
}

#Preview {
    let image = ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1.jpg"),
                           validImage: true,
                           dateTimeCreated: "2022:12:12 11:22:33",
                           latitude: 33.123,
                           longitude: 123.456)
    return LatLonSectionView(image: image)
        .environment(AppState())
}
