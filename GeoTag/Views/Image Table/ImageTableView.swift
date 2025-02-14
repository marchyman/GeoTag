//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import OSLog
import SwiftUI

struct ImageTableView: View {
    @Bindable var tvm: TableViewModel

    @AppStorage(AppSettings.imageTableConfigKey)
    private var columnCustomization: TableColumnCustomization<ImageModel>
    @AppStorage(AppSettings.coordFormatKey)
    var coordFormat: AppSettings.CoordFormat = .deg
    @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false

    // table view column width limits
    let nameMinWidth = 100.0
    let nameMaxWidth = 200.0
    let timestampMinWidth = 130.0
    let timestampMaxWidth = 150.0
    let coordMinWidth = 120.0
    let coordMaxWidth = 160.0

    var filteredImages: [ImageModel] {
        return tvm.searchImages.isEmpty
            ? hideInvalidImages
                ? tvm.images.filter { $0.isValid }
                : tvm.images
            : tvm.searchImages
    }

    @State private var searchFor: String = ""
    @State private var isSearching: Bool = false

    var body: some View {
        // force the view to notice changes in tvm.mostSelected and coordFormat
        let mostSelected = tvm.mostSelected
        // swiftlint:disable redundant_discardable_let
        let _ = coordFormat
        // swiftlint:enable redundant_discardable_let

        Table(
            of: ImageModel.self,
            selection: $tvm.selection,
            sortOrder: $tvm.sortOrder,
            columnCustomization: $columnCustomization
        ) {

            TableColumn("Name", value: \.name) { image in
                NameView(image: image, isSelected: image == mostSelected)
            }
            .width(min: nameMinWidth, max: nameMaxWidth)
            .customizationID("Name")

            TableColumn("Timestamp", value: \.timeStamp) { image in
                TimestampView(image: image)
            }
            .width(min: timestampMinWidth, max: timestampMaxWidth)
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
            ForEach(filteredImages) { image in
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
        .searchable(
            text: $searchFor, isPresented: $isSearching,
            placement: .automatic, prompt: "Image name"
        )
        .background(
            // cmd-f for search
            Button(
                "",
                action: { isSearching = true }
            )
            .keyboardShortcut("f").hidden()
            .disabled(tvm.images.isEmpty)
        )
        .onChange(of: searchFor) {
            if searchFor.isEmpty {
                tvm.clearSearch()
            }
        }
        .onSubmit(of: .search) {
            tvm.search(for: searchFor)
            isSearching = false
        }
    }
}

struct NameView: View {
    let image: ImageModel
    let isSelected: Bool

    var body: some View {
        Text(image.name)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(
                isSelected
                    ? .mostSelected
                    : image.isValid ? .primary : .secondary
            )
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
    @AppStorage(AppSettings.coordFormatKey)
    var coordFormat: AppSettings.CoordFormat = .deg

    var body: some View {
        Text(image.formattedLatitude)
            .foregroundColor(image.locationTextColor)
    }
}

struct LongitudeView: View {
    let image: ImageModel
    @AppStorage(AppSettings.coordFormatKey)
    var coordFormat: AppSettings.CoordFormat = .deg

    var body: some View {
        Text(image.formattedLongitude)
            .foregroundColor(image.locationTextColor)
    }
}

struct ImageTableView_Previews: PreviewProvider {

    static var images = [
        ImageModel(
            imageURL: URL(fileURLWithPath: "/test/path/to/image1.jpg"),
            validImage: true,
            dateTimeCreated: "2022:12:12 11:22:33",
            latitude: 33.123,
            longitude: 123.456),
        ImageModel(
            imageURL: URL(fileURLWithPath: "/test/path/to/image2.bad"),
            validImage: false,
            dateTimeCreated: "",
            latitude: nil,
            longitude: nil),
        ImageModel(
            imageURL: URL(fileURLWithPath: "/test/path/to/image3.dng"),
            validImage: true,
            dateTimeCreated: "2022:12:13 14:15:16",
            latitude: 35.505,
            longitude: -123.456)
    ]

    static var previews: some View {
        ImageTableView(tvm: TableViewModel(images: images))
    }
}
