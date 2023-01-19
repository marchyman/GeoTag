//
//  ImageLatitudeColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageLatitudeColumnView: View {
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
    @State private var showPopover = false

    let vm: ViewModel
    let id: ImageModel.ID

    var body: some View {
        Text(coordToString(for: vm[id].location?.latitude,
                           format: coordFormat,
                           ref: latRef))
            .foregroundColor(vm[id].locationTextColor)
            .frame(minWidth: coordMinWidth)
            .onDoubleClick() {
                showPopover = vm[id].isValid
            }
            .popover(isPresented: self.$showPopover) {
                ChangeLocationView(vm: vm, id: id)
                    .frame(width: 450, height: 250)
            }
            .help(vm.elevationAsString(id: id))
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
        let vm = ViewModel(images: [image])
        ImageLatitudeColumnView(vm: vm, id: image.id)
    }
}
