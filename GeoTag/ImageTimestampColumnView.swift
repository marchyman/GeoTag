//
//  ImageTimestampColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageTimestampColumnView: View {
    @ObservedObject var vm: ViewModel
    let id: ImageModel.ID
    @State private var showPopover = false

    var body: some View {
        Text(vm[id].timeStamp)
            .foregroundColor(vm[id].timestampTextColor)
            .frame(minWidth: timestampMinWidth)
            .onDoubleClick() {
                showPopover = vm[id].isValid
            }
            .popover(isPresented: self.$showPopover) {
                ChangeDateTimeView(vm: vm, id: id)
            }
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
        let vm = ViewModel(images: [image])
        ImageTimestampColumnView(vm: vm, id: image.id)
    }
}
