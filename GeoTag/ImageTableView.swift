//
//  ImageTableView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI

struct ImageTableView: View {
    @Binding var images: [ImageModel]

    @State private var sortOrder = [KeyPathComparator(\ImageModel.name)]
    @State private var selection = Set<ImageModel.ID>()

    var body: some View {
        Table(images, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Image Name", value: \.name) { image in
                ImageNameColumnView(image: image)
            }
            TableColumn("Timestamp", value: \.timeStamp)
            TableColumn("Latitude", value: \.latitude) { image in
                Text(image.latitude)
            }
            TableColumn("Longitude", value: \.longitude) { image in
                Text(image.longitude)
            }
        }
        .onChange(of: sortOrder) { newOrder in
            images.sort(using: newOrder)
        }
        .onChange(of: selection) { selection in
            for item in selection {
                let image = images.first { $0.id == item }
                if let image, !image.validImage {
                    print("This item should be removed from selection \(item)")
                }
            }
        }
        .onAppear {
            selection = Set()
        }
    }
}


/// Computed properties to convert elements of an imageModel into strings for use with
/// this view
extension ImageModel {
    var name: String {
        fileURL.lastPathComponent
    }
    var timeStamp: String {
        dateTimeCreated ?? ""
    }
    var latitude: String {
        location?.dms.latitude ?? ""
    }
    var longitude: String {
        location?.dms.longitude ?? ""
    }

}

struct ImageTableView_Previews: PreviewProvider {
    static var images = [
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: 123.456),
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image2"),
                   validImage: false,
                   dateTimeCreated: "",
                   latitude: nil,
                   longitude: nil),
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image3"),
                   validImage: true,
                   dateTimeCreated: "2022:12:13 14:15:16",
                   latitude: 35.505,
                   longitude: -123.456),

    ]
    static var previews: some View {
        ImageTableView(images: .constant(images))
    }
}
