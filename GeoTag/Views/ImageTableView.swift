import Coords
import ImageData
import SwiftUI
import UDF

struct ImageTableView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    @AppStorage(Self.imageTableConfigKey)
    private var columnCustomization: TableColumnCustomization<ImageData>

    @AppStorage(Self.coordFormatKey) var coordFormat: CoordFormat = .deg
    @AppStorage(Self.hideInvalidImagesKey) var hideInvalidImages = false

    // Column width limits
    let nameMinWidth = 100.0
    let nameMaxWidth = 300.0
    let timestampMinWidth = 130.0
    let timestampMaxWidth = 150.0
    let coordMinWidth = 120.0
    let coordMaxWidth = 160.0

    @State private var searchFor: String = ""
    @State private var isSearching: Bool = false
    @State private var selection: Set<ImageData.ID> = []
    @State private var sortOrder = [KeyPathComparator(\ImageData.name)]

    var filteredImages: [ImageData] {
        return store.searchImages.isEmpty
            ? hideInvalidImages
                ? store.imageData.filter { $0.updatable }
                : store.imageData
            : store.searchImages
    }

    var body: some View {
        Table(of: ImageData.self,
              selection: $selection,
              sortOrder: $sortOrder,
              columnCustomization: $columnCustomization) {
            TableColumn("Name", value: \.name) { image in
                NameView(image: image, isSelected: image.id == store.mostSelected)
            }
            .width(min: nameMinWidth, max: nameMaxWidth)
            .customizationID("Name")

            TableColumn("Timestamp", value: \.metadata.timestamp) { image in
                TimestampView(image: image)
            }
            .width(min: timestampMinWidth, max: timestampMaxWidth)
            .customizationID("Timestamp")

            TableColumn("Latitude", value: \.metadata.formattedLatitude) { image in
                LatitudeView(image: image)
            }
            .width(min: coordMinWidth, max: coordMaxWidth)
            .customizationID("Latitude")

            TableColumn("Longitude", value: \.metadata.formattedLongitude) { image in
                LongitudeView(image: image)
            }
            .width(min: coordMinWidth, max: coordMaxWidth)
            .customizationID("Longitude")
        } rows: {
            ForEach(filteredImages) { image in
                TableRow(image)
                    // .contextMenu {
                    //     ContextMenuView(context: image)
                    // }
            }
        }
        // .contextMenu {
        //     ContextMenuView(context: nil)
        // }
        .onChange(of: selection) {
            store.send(.selectionChanged(selection)) {
                store.discardUndo()
                selection = store.selection
            }
        }
        .onChange(of: sortOrder) {
            if sortOrder != store.sortOrder {
                store.send(.sortOrderChanged(sortOrder))
                store.discardUndo()
            }
        }
        .searchable(text: $searchFor, isPresented: $isSearching,
                    placement: .automatic, prompt: "Image name")
        .background(
            // cmd-f for search
            Button("", action: { isSearching = true })
                .keyboardShortcut("f").hidden()
                .disabled(store.imageData.isEmpty)
        )
        .onSubmit(of: .search) {
            store.send(.searchForChanged(searchFor))
            isSearching = false
        }
        .onChange(of: searchFor) {
            if searchFor.isEmpty {
                store.send(.searchForCleared)
            }
        }
        .onAppear {
            sortOrder = store.sortOrder
        }
    }
}

// ImageTableView AppStorage keys

extension ImageTableView {
    static let imageTableConfigKey = "ImageTableConfig"
    static let coordFormatKey = "CoordFormat"
    static let hideInvalidImagesKey = "HideInvalidImages"
}

// ImageTableView column views

struct NameView: View {
    let image: ImageData
    let isSelected: Bool

    var body: some View {
        Text(image.name)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(
                isSelected
                    ? .mostSelected
                    : image.updatable
                        ? .primary
                        : .secondary
            )
            .truncationMode(.middle)
            .help("Full path: \(image.fullPath)")
    }
}

struct TimestampView: View {
    let image: ImageData

    var body: some View {
        Text(image.metadata.timestamp)
            .foregroundColor(image.timestampTextColor)
    }
}
struct LatitudeView: View {
    let image: ImageData
    @AppStorage(Coords.coordFormatKey)
    var coordFormat: CoordFormat = .deg

    var body: some View {
        Text(image.metadata.formattedLatitude)
            .foregroundColor(image.locationTextColor)
            .help(image.metadata.formattedElevation)
    }
}

struct LongitudeView: View {
    let image: ImageData
    @AppStorage(Coords.coordFormatKey)
    var coordFormat: CoordFormat = .deg

    var body: some View {
        Text(image.metadata.formattedLongitude)
            .foregroundColor(image.locationTextColor)
            .help(image.metadata.formattedElevation)
    }
}
