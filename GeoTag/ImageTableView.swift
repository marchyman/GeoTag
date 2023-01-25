//
//  ImageTableView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI

let timestampMinWidth = 130.0
let coordMinWidth = 120.0

// Note on EnvironmentObject:  When testing scrolling the Table in this view
// would crash when trying to render one of the columns.   The crash was
// due to the @EnvironmentObject being empty!  To get around this do not
// rely on the Environment.  Explicitly pass the ViewModel to the column views.

struct ImageTableView: View {
    @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false
    @EnvironmentObject var vm: ViewModel
    @Environment(\.openWindow) var openWindow

    @State private var selection = Set<ImageModel.ID>()
    @State private var sortOrder = [KeyPathComparator(\ImageModel.name)]

    var body: some View {
        Table(selection: $selection,
              sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { image in
                ImageNameColumnView(vm: vm, id: image.id)
            }
            .width(min: 100)

            TableColumn("Timestamp", value: \.timeStamp) { image in
                ImageTimestampColumnView(vm: vm, id: image.id)
            }
            .width(min: timestampMinWidth)

            TableColumn("Latitude", value: \.latitude) { image in
                ImageLatitudeColumnView(vm: vm, id: image.id)
            }
            .width(min: coordMinWidth)

            TableColumn("Longitude", value: \.longitude) { image in
                ImageLongitudeColumnView(vm: vm, id: image.id)
            }
            .width(min: coordMinWidth)
        } rows: {
            ForEach(vm.images) { image in
                if image.isValid || !hideInvalidImages {
                    TableRow(image)
                        .contextMenu {
                            ContextMenuView(context: image.id)
                        }
                }
            }
        }
        .contextMenu {
            ContextMenuView(context: nil)
        }
        .onChange(of: sortOrder) { newOrder in
            vm.images.sort(using: newOrder)
        }
        .onChange(of: selection) { selection in
            vm.selectionChanged(newSelection: selection)
        }
        .onChange(of: vm.selectedMenuAction) { action in
            if action != .none {
                vm.menuAction(action, openWindow: openWindow)
            }
        }
        .dropDestination(for: URL.self) {items, location in
            vm.prepareForEdit(inputURLs: items)
            return true
        }
        .link($vm.selection, with: $selection)
    }
}


/// Computed properties to convert elements of an imageModel into values for use with
/// this view, espeically with regard to sorting.
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

    var timestampTextColor: Color {
        if isValid {
            if dateTimeCreated == originalDateTimeCreated {
                return .primary
            }
            return .changed
        }
        return .secondary
    }

    var locationTextColor: Color {
        if isValid {
            if location == originalLocation {
                return .primary
            }
            return .changed
        }
        return .secondary
    }

}

extension ViewModel {
    func elevationAsString(id: ImageModel.ID) -> String {
        var value = "Elevation: "
        if let elevation = self[id].elevation {
            value += String(format: "% 4.2f", elevation)
            value += " meters"
        } else {
            value += "Unknown"
        }
        return value
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
            .environmentObject(ViewModel(images: images))
    }
}
