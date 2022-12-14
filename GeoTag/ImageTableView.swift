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
        Table(images, sortOrder: $sortOrder) {
            TableColumn("Image Name", value: \.name) { image in
                Text(image.name)
                    .help("Full path: \(image.fileURL.path)")
            }
            TableColumn("Timestamp", value: \.dateTimeCreated)
            TableColumn("Latitude", value: \.location.latitude) { image in
                Text(image.location.dms.latitude)
            }
            TableColumn("Longitude", value: \.location.longitude) { image in
                Text(image.location.dms.longitude)
            }
        }
        .onChange(of: sortOrder) { newOrder in
            images.sort(using: newOrder)
        }
        .onChange(of: selection) { selection in
            print("Selection changed: \(selection)")
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
    var latitude: String {
        location.dms.latitude
    }
    var longitude: String {
        location.dms.longitude
    }

}

struct ImageTableView_Previews: PreviewProvider {
    static var previews: some View {
        ImageTableView(images: .constant([ImageModel.sample]))
    }
}
