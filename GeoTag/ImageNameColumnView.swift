//
//  ImageNameColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/15/22.
//

import SwiftUI

struct ImageNameColumnView: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    let image: ImageModel

    var body: some View {
        Text(image.name + ((image.sandboxXmpURL == nil) ? "" : "*"))
            .foregroundColor(image.validImage ?
                             AppSettings.textColor(colorScheme) : .gray)
            .help("Full path: \(image.fileURL.path)")
    }

}

struct ImageNameColumnView_Previews: PreviewProvider {
    static var image =
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: 123.456)
    static var previews: some View {
        ImageNameColumnView(image: image)
    }
}
