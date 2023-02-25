//
//  ImageTimestampColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageTimestampColumnView: View {
    @ObservedObject var itvm = ImageTableViewModel.shared
    @State private var showPopover = false

    @ObservedObject var avm: AppViewModel
    let id: ImageModel.ID

    var body: some View {
        Text(avm[id].timeStamp)
            .foregroundColor(avm[id].timestampTextColor)
            .frame(minWidth: itvm.timestampMinWidth)
            .onDoubleClick {
                showPopover = avm[id].isValid
            }
            .popover(isPresented: self.$showPopover) {
                ChangeDateTimeView(avm: avm, id: id)
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
        let vm = AppViewModel(images: [image])
        ImageTimestampColumnView(avm: vm, id: image.id)
    }
}
