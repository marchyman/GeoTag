//
//  ImageTableView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI

struct ImageTableView: View {
    @EnvironmentObject var appState: AppState

    @State private var sortOrder = [KeyPathComparator(\ImageModel.name)]

    var body: some View {
        Table(selection: $appState.selection,
              sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { image in
                ImageNameColumnView(image: image)
            }
            .width(min: 100)
            TableColumn("Timestamp", value: \.timeStamp) { image in
                ImageTimestampColumnView(image: image)
            }
            .width(min: 130)
            TableColumn("Latitude", value: \.latitude) { image in
                ImageLatitudeColumnView(image:image)
            }
            .width(min: 120)
            TableColumn("Longitude", value: \.longitude) { image in
                ImageLongitudeColumnView(image:image)
            }
            .width(min: 120)
        } rows: {
            ForEach(appState.images) { image in
                TableRow(image)
                    .contextMenu {
                        ContextMenuView(context: image)
                    }
            }
        }
        .contextMenu {
            ContextMenuView(context: nil)
        }
        .onChange(of: sortOrder) { newOrder in
            appState.images.sort(using: newOrder)
            appState.selection = Set()
        }
        .onChange(of: appState.selection) { selection in
            appState.selectionChanged(newSelection: selection)
        }
        .onChange(of: appState.selectedMenuAction) { action in
            if action != .none {
                appState.menuAction(action)
            }
        }
        .dropDestination(for: URL.self) {items, location in
            // appstate is @MainActor yet I want to run this in the
            // background.   How to do that?
            appState.prepareForEdit(inputURLs: items)
            return true
        }
        .onAppear {
            appState.selection = Set()
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
    var latitude: Double {
        location?.latitude ?? 0.0
    }
    var longitude: Double {
        location?.longitude ?? 0.0
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
        ImageTableView()
            .environmentObject(AppState(images: images))
    }
}
