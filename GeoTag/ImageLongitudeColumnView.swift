//
//  ImageLongitudeColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageLongitudeColumnView: View {
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg

    let image: ImageModel

    var body: some View {
        Text(longitudeToString())
            .foregroundColor(image.validImage ? .primary : .gray)
    }

    func longitudeToString() -> String {
        if let location = image.location {
            switch coordFormat {
            case .deg:
                return String(format: "% 2.6f", location.longitude)
            case .degMin:
                return location.dm.longitude
            case .degMinSec:
                return location.dms.longitude
            }
        }
        return ""
    }
}

struct ImageLongitudeColumnView_Previews: PreviewProvider {
    static var image =
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: -123.456)

    static var previews: some View {
        ImageLongitudeColumnView(image: image)
    }
}
