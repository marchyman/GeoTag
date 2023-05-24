//
//  ImageLongitudeColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageLongitudeColumnView: View {
    let image: ImageModel
    let coordFormat: AppSettings.CoordFormat
    let minWidth: CGFloat

    @State private var showPopover = false

    var body: some View {
        Text(coordToString(for: image.location?.longitude,
                           format: coordFormat,
                           ref: lonRef))
            .foregroundColor(image.locationTextColor)
            .frame(minWidth: minWidth)
            .onDoubleClick {
                showPopover = image.isValid
            }
            .popover(isPresented: self.$showPopover) {
                ChangeLocationView(id: image.id)
                    .frame(width: 450, height: 250)
            }
            .help(image.elevationAsString)
    }
}

struct ImageLongitudeColumnView_Previews: PreviewProvider {
    static var image =
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: 123.456)

    static var previews: some View {
        let avm = AppViewModel(images: [image])
        ImageLongitudeColumnView(image: image,
                                 coordFormat: .deg,
                                 minWidth: 120.0)
            .environmentObject(avm)
    }
}
