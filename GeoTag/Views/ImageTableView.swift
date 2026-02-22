import Coords
import ImageData
import SwiftUI
import UDF

struct ImageTableView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    @AppStorage(Self.imageTableConfigKey)
    private var columnCustomization: TableColumnCustomization<ImageData>

    @AppStorage(Self.hideInvalidImagesKey) var hideInvalidImages = false

    // Column width limits
    let nameMinWidth = 100.0
    let nameMaxWidth = 300.0
    let timestampMinWidth = 130.0
    let timestampMaxWidth = 150.0
    let coordMinWidth = 120.0
    let coordMaxWidth = 160.0

    @State private var searchActive = false
    @State private var searchText = ""
    @State private var selection: Set<ImageData.ID> = []
    @State private var sortOrder = [KeyPathComparator(\ImageData.name)]

    var filteredImages: [ImageData] {
        return store.searchText.isEmpty
            ? hideInvalidImages
                ? store.imageData.filter { $0.updatable }
                : store.imageData
            : store.imageData.filter { $0.name.fuzzy(store.searchText) }
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
                    .contextMenu {
                        ContextMenuView(context: image.id)
                    }
            }
        }
        .contextMenu {
            ContextMenuView(context: nil)
        }
        .onChange(of: selection) {
            if selection != store.selection {
                store.send(.selectionChanged(selection), undoable: false)
            }
        }
        .onChange(of: store.selection) {
            if selection != store.selection {
                selection = store.selection
            }
        }
        .onChange(of: sortOrder) {
            if sortOrder != store.sortOrder {
                store.send(.sortOrderChanged(sortOrder), undoable: false)
            }
        }
        .searchable(text: $searchText, isPresented: $searchActive,
                    placement: .automatic, prompt: "image name")
        .onChange(of: searchActive) {
            if searchActive != store.searchActive {
                store.send(.searchActiveChanged(searchActive))
            }
        }
        .background(
            // ⌘F for search
            Button("", action: { searchActive = true })
                .keyboardShortcut("f", modifiers: .shift).hidden()
                .disabled(store.imageData.isEmpty)
        )
        .onChange(of: searchText) {
            store.send(.searchTextChanged(searchText))
        }
        .onAppear {
            sortOrder = store.sortOrder
        }
    }
}

// ImageTableView AppStorage keys

extension ImageTableView {
    static let imageTableConfigKey = "ImageTableConfig"
    static let hideInvalidImagesKey = "HideInvalidImages"
}
