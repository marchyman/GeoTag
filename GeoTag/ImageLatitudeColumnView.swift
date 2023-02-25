//
//  ImageLatitudeColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageLatitudeColumnView: View {
    @ObservedObject var itvm = ImageTableViewModel.shared
    @State private var showPopover = false

    @ObservedObject var avm: AppViewModel
    let id: ImageModel.ID

    var body: some View {
        Text(coordToString(for: avm[id].location?.latitude,
                           format: itvm.coordFormat,
                           ref: latRef))
            .foregroundColor(avm[id].locationTextColor)
            .frame(minWidth: itvm.coordMinWidth)
            .onDoubleClick {
                showPopover = avm[id].isValid
            }
            .popover(isPresented: self.$showPopover) {
                ChangeLocationView(avm: avm, id: id)
                    .frame(width: 450, height: 250)
            }
            .help(avm.elevationAsString(id: id))
    }
}

struct ImageLatitudeColumnView_Previews: PreviewProvider {
    static var image =
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: 123.456)

    static var previews: some View {
        let avm = AppViewModel(images: [image])
        ImageLatitudeColumnView(avm: avm, id: image.id)
    }
}
