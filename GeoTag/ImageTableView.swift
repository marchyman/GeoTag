//
//  ImageTableView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI

// Note on EnvironmentObject:  When testing scrolling the Table in this view
// would crash when trying to render one of the columns.   The crash was
// due to the @EnvironmentObject being empty!  To get around this do not
// rely on the Environment.  Explicitly pass the ViewModel to the column views.

struct ImageTableView: View {
    @EnvironmentObject var avm: AppViewModel
    @ObservedObject var itvm = ImageTableViewModel.shared

    @State private var sortOrder = [KeyPathComparator(\ImageModel.name)]

    var body: some View {
        Table(selection: $avm.selection,
              sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { image in
                ImageNameColumnView(avm: avm,
                                    id: image.id,
                                    selected: avm.mostSelected == image.id)
            }
            .width(min: 100)

            TableColumn("Timestamp", value: \.timeStamp) { image in
                ImageTimestampColumnView(avm: avm,
                                         id: image.id,
                                         timestampMinWidth: itvm.timestampMinWidth)
            }
            .width(min: itvm.timestampMinWidth)

            TableColumn("Latitude", value: \.latitude) { image in
                ImageLatitudeColumnView(avm: avm,
                                        id: image.id,
                                        coordFormat: itvm.coordFormat,
                                        minWidth: itvm.coordMinWidth)
            }
            .width(min: itvm.coordMinWidth)

            TableColumn("Longitude", value: \.longitude) { image in
                ImageLongitudeColumnView(avm: avm,
                                         id: image.id,
                                         coordFormat: itvm.coordFormat,
                                         minWidth: itvm.coordMinWidth)
            }
            .width(min: itvm.coordMinWidth)
        } rows: {
            ForEach(avm.images) { image in
                if image.isValid || !avm.hideInvalidImages {
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
            avm.sortOrder = newOrder
            avm.images.sort(using: newOrder)
        }
        .onChange(of: avm.selection) { _ in
            avm.selectionChanged()
        }
    }
}

/// Computed properties to convert elements of an imageModel into values for use with
/// this view, espeically with regard to sorting and display.
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

    var elevationAsString: String {
        var value = "Elevation: "
        if let elevation {
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
                   longitude: -123.456)
    ]
    static var previews: some View {
        ImageTableView()
            .environmentObject(AppViewModel(images: images))
    }
}
