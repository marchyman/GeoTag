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

    let coordMinWidth = 120.0
    let coordMaxWidth = 150.0

    @AppStorage(AppSettings.imageTableConfigKey)
    private var columnCustomization: TableColumnCustomization<ImageModel>
    @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false

    var body: some View {
        Table(of: ImageModel.self,
              selection: $tvm.selection,
              sortOrder: $tvm.sortOrder,
              columnCustomization: $columnCustomization) {

            TableColumn("Name", value: \.name) { image in
                NameView(image: image, isSelected: image == tvm.mostSelected)
            }
            .width(min: 100, max: 150)
            .customizationID("Name")

            TableColumn("Timestamp", value: \.timeStamp) { image in
                TimestampView(image: image)
            }
            .width(min: 130, max: 150)
            .customizationID("Timestamp")

            TableColumn("Latitude", value: \.formattedLatitude) { image in
                LatitudeView(image: image)
            }
            .width(min: coordMinWidth, max: coordMaxWidth)
            .customizationID("Latitude")

            TableColumn("Longitude", value: \.formattedLongitude) { image in
                LongitudeView(image: image)
            }
            .width(min: coordMinWidth, max: coordMaxWidth)
            .customizationID("Longitude")
        } rows: {
            ForEach(hideInvalidImages
                    ? tvm.images.filter { $0.isValid }
                    : tvm.images) { image in
                TableRow(image)
                    .contextMenu {
                        ContextMenuView(context: image)
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

struct NameView: View {
    let image: ImageModel
    let isSelected: Bool

    var body: some View {
        Text(image.name)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected
                             ? .mostSelected
                             : image.isValid ? .primary : .secondary)
            .help("Full path: \(image.fileURL.path())")
    }
}

struct TimestampView: View {
    let image: ImageModel

    var body: some View {
        Text(image.timeStamp)
            .foregroundColor(image.timestampTextColor)
    }
}
struct LatitudeView: View {
    let image: ImageModel

    var body: some View {
        Text(image.formattedLatitude)
            .foregroundColor(image.locationTextColor)
    }
}

struct LongitudeView: View {
    let image: ImageModel

    var body: some View {
        Text(image.formattedLongitude)
            .foregroundColor(image.locationTextColor)
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
