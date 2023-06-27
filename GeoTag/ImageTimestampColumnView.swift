//
//  ImageTimestampColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageTimestampColumnView: View {
    let id: ImageModel.ID
    let timestampMinWidth: CGFloat
    @EnvironmentObject var avm: AppViewModel

    @State private var dateTimePopover = false

    var body: some View {
        Text(avm[id].timeStamp)
            .foregroundColor(avm[id].timestampTextColor)
            .frame(minWidth: timestampMinWidth)
            .onDoubleClick {
                dateTimePopover = avm[id].isValid
            }
            .popover(isPresented: self.$dateTimePopover) {
                ChangeDateTimeView(id: id)
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
        ImageTimestampColumnView(id: image.id,
                                 timestampMinWidth: 130.0)
            .environmentObject(AppViewModel(images: [image]))
    }
}
