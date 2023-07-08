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

// Note on EnvironmentObject:  When testing scrolling the Table in this view
// would crash when trying to render one of the columns.   The crash was
// due to the @EnvironmentObject being empty!  To get around this do not
// rely on the Environment.  Explicitly pass the ViewModel to the column views.

struct ImageTableView: View {
    @EnvironmentObject var avm: AppViewModel

    @State private var sortOrder = [KeyPathComparator(\ImageModel.name)]

    let timestampMinWidth = 130.0
    let coordMinWidth = 120.0

    var body: some View {
        Table(of: ImageModel.self,
              selection: $avm.selection,
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
                if image.isValid || !avm.hideInvalidImages {
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
        .onChange(of: sortOrder) { newOrder in
            avm.sortOrder = newOrder
            avm.images.sort(using: newOrder)
        }
        .onChange(of: avm.selection) { _ in
            avm.selectionChanged()
        }
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
            .environmentObject(AppViewModel(images: images))
    }
}
