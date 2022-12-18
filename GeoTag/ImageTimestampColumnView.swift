//
//  ImageTimestampColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageTimestampColumnView: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    let image: ImageModel

    var body: some View {
        Text(image.timeStamp)
            .foregroundColor(image.validImage ?
                             AppSettings.textColor(colorScheme) : .gray)
    }
}

struct ImageTimestampColumnView_Previews: PreviewProvider {
    static var image =
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: 123.456)
    static var previews: some View {
        ImageTimestampColumnView(image: image)
    }
}
