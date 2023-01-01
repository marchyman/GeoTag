//
//  ImageTimestampColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageTimestampColumnView: View {
    @State private var showPopover = false
    @EnvironmentObject var vm: AppState
    let id: ImageModel.ID

    var body: some View {
        Text(vm[id].timeStamp)
            .foregroundColor(textColor())
            .onRightClick {
                print("Right Click -- on timestamp")
            }
            .onDoubleClick {
                showPopover.toggle()
            }
            .popover(isPresented: self.$showPopover) {
                Text("Popover -- this is where date/time change will take place.")
                    .padding()
            }
    }

    func textColor() -> Color {
        if vm[id].isValid {
            if vm[id].dateTimeCreated == vm[id].originalDateTimeCreated {
                return .primary
            }
            return .changed
        }
        return .secondary
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
        ImageTimestampColumnView(id: image.id)
            .environmentObject(AppState(images: [image]))
    }
}
