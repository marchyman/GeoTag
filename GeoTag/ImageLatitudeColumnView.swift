//
//  ImageLatitudeColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageLatitudeColumnView: View {
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
    @EnvironmentObject var vm: ViewModel
    @Environment(\.openWindow) var openWindow
    let id: ImageModel.ID
    @State private var showPopover = false

    var body: some View {
        Text(coordToString(for: vm[id].location?.latitude,
                           format: coordFormat,
                           ref: latRef))
            .foregroundColor(textColor())
            .frame(minWidth: coordMinWidth)
            .onDoubleClick() {
                showPopover.toggle()
            }
            .popover(isPresented: self.$showPopover) {
                ChangeLocationView(id: id)
                    .frame(width: 450, height: 250)
            }
            .help(vm.elevationAsString(id: id))
    }

    func textColor() -> Color {
        if vm[id].isValid {
            if vm[id].location == vm[id].originalLocation {
                return .primary
            }
            return .changed
        }
        return .secondary
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
        ImageLatitudeColumnView(id: image.id)
            .environmentObject(ViewModel(images: [image]))
    }
}
