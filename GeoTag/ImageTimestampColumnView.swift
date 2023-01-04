//
//  ImageTimestampColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageTimestampColumnView: View {
    @EnvironmentObject var vm: ViewModel
    @Environment(\.openWindow) var openWindow

    let id: ImageModel.ID

    var body: some View {
        Text(vm[id].timeStamp)
            .foregroundColor(textColor())
            .onDoubleClick {
                vm.menuContext = id
                openWindow(id: GeoTagApp.modifyDateTime)
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
            .environmentObject(ViewModel(images: [image]))
    }
}
