//
//  ImageTableView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI
import OSLog

struct ImageTableView: View {
    @Bindable var tvm: TableViewModel

    let timestampMinWidth = 130.0
    let coordMinWidth = 120.0

    @AppStorage(AppSettings.imageTableConfigKey)
    private var columnCustomization: TableColumnCustomization<ImageModel>
    @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false

    var body: some View {
        Table(of: ImageModel.self,
              selection: $tvm.selection,
              sortOrder: $tvm.sortOrder,
              columnCustomization: $columnCustomization) {

            TableColumn("Name", value: \.name) { image in
                ImageNameColumnView(image: image,
                                    selectedImage: image === tvm.mostSelected)
            }
            .width(min: 100)
            .customizationID("Name")

            TableColumn("Timestamp", value: \.timeStamp) { image in
                ImageTimestampColumnView(image: image)
            }
            .width(min: timestampMinWidth)
            .customizationID("Timestamp")

            TableColumn("Latitude", value: \.formattedLatitude) { image in
                ImageLatitudeColumnView(image: image)
            }
            .width(min: coordMinWidth)
            .customizationID("Latitude")

            TableColumn("Longitude", value: \.formattedLongitude) { image in
                ImageLongitudeColumnView(image: image)
            }
            .width(min: coordMinWidth)
            .customizationID("Longitude")
        } rows: {
            let showAllImages = !hideInvalidImages
            ForEach(tvm.images) { image in
                if image.isValid || showAllImages {
                    TableRow(image)
                        .contextMenu {
                            ContextMenuView(context: image)
                        }
                }
            }
        }
        .contextMenu {
            ContextMenuView(context: nil)
        }
        .onChange(of: tvm.sortOrder) {
            tvm.images.sort(using: tvm.sortOrder)
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
        ImageTableView(tvm: TableViewModel(images: images))
    }
}
