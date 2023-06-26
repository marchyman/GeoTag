//
//  ImageNameColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/15/22.
//

import SwiftUI

struct ImageNameColumnView: View {
    let image: ImageModel
    let selectedImage: Bool

    var body: some View {
        let name = image.name + (image.sidecarExists ? "*" : "")
        Text(name)
            .fontWeight(selectedImage ? .semibold : .regular)
            .foregroundColor(selectedImage ? .mostSelected :
                                image.isValid ? .primary : .secondary)
            .help("Full path: \(image.fileURL.path)")
    }
}

struct ImageNameColumnView_Previews: PreviewProvider {
    static var image =
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1.jpg"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: 123.456)

    static var previews: some View {
        ImageNameColumnView(image: image,
                            selectedImage: true)

    }
}
