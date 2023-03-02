//
//  ImageNameColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/15/22.
//

import SwiftUI

struct ImageNameColumnView: View {
    @ObservedObject var avm: AppViewModel
    let id: ImageModel.ID

    var body: some View {
        Text(avm[id].name + ((avm[id].sidecarExists) ? "*" : ""))
            .fontWeight(textWeight())
            .foregroundColor(textColor())
            .help("Full path: \(avm[id].fileURL.path)")
    }

    @MainActor
    func textColor() -> Color {
        if avm[id].isValid {
            if id == avm.mostSelected {
                return .mostSelected
            }
            return .primary
        }
        return .secondary
    }

    @MainActor
    func textWeight() -> Font.Weight {
        id == avm.mostSelected ? .semibold : .regular
    }
}

struct ImageNameColumnView_Previews: PreviewProvider {
    static var image =
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: 123.456)

    static var previews: some View {
        let avm = AppViewModel(images: [image])
        ImageNameColumnView(avm: avm, id: image.id)
    }
}
