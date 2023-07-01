//
//  ImageTableView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI
import OSLog

let tableLog = Logger(subsystem: Bundle.main.bundleIdentifier!,
                      category: "ImageTableView")
let tableSP = OSSignposter(logger: tableLog)

struct ImageTableView: View {
    @Environment(AppViewModel.self) var avm

    @State private var sortOrder = [KeyPathComparator(\ImageModel.name)]

    let timestampMinWidth = 130.0
    let coordMinWidth = 120.0

    var body: some View {
        @Bindable var avm = avm
        Table(selection: $avm.selection,
              sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { image in
                ImageNameColumnView(image: image,
                                    selectedImage: image.id == avm.mostSelected)
            }
            .width(min: 100)

            TableColumn("Timestamp", value: \.timeStamp) { image in
                ImageTimestampColumnView(id: image.id,
                                         timestampMinWidth: timestampMinWidth)
            }
            .width(min: timestampMinWidth)

            TableColumn("Latitude", value: \.latitude) { image in
                ImageLatitudeColumnView(id: image.id)
            }
            .width(min: coordMinWidth)

            TableColumn("Longitude", value: \.longitude) { image in
                ImageLongitudeColumnView(id: image.id)
            }
            .width(min: coordMinWidth)
        } rows: {
            let spID = tableSP.makeSignpostID()
            let spState = tableSP.beginInterval("Table Rows", id: spID)
            ForEach(avm.images) { image in
                @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false

                if image.isValid || !hideInvalidImages {
                    TableRow(image)
                        .contextMenu {
                            ContextMenuView(context: image.id)
                        }
                }
            }
            // swiftlint:disable redundant_discardable_let
            let _ = tableSP.endInterval("Table Rows", spState)
            // swiftlint:enable redundant_discardable_let
        }
        .contextMenu {
            ContextMenuView(context: nil)
        }
        .onChange(of: sortOrder) {
            avm.images.sort(using: sortOrder)
        }
        .onChange(of: avm.selection) {
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
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1.jpg"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: 123.456),
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image2.bad"),
                   validImage: false,
                   dateTimeCreated: "",
                   latitude: nil,
                   longitude: nil),
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image3.dng"),
                   validImage: true,
                   dateTimeCreated: "2022:12:13 14:15:16",
                   latitude: 35.505,
                   longitude: -123.456)
    ]

    static var previews: some View {
        ImageTableView()
            .environment(AppViewModel(images: images))
    }
}
