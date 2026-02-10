import ImageData
import OSLog
import SplitHView
import SplitVView
import SwiftUI
import UDF
import UniformTypeIdentifiers

/// Window look and feel values
let windowBorderColor = Color.gray

struct ContentView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
    @Environment(\.openWindow) var openWindow

    @AppStorage(Self.alternateLayoutKey) var alternateLayout = false
    @AppStorage(Self.splitHNormalKey) var hNormal = 0.45
    @AppStorage(Self.splitHAlternateKey) var hAlternate = 0.55
    @AppStorage(Self.splitVNormalKey) var vNormal = 0.60
    @AppStorage(Self.splitVAlternateKey) var vAlternate = 0.40

    // @State private var removeOldFiles = false
    @State private var sheetType: SheetType?
    @State private var importFiles = false

    var body: some View {
        SplitHView(percent: alternateLayout ? $hAlternate : $hNormal) {
            Group {
                if alternateLayout {
                    SplitVView(percent: $vAlternate) {
                        ImageTableView()
                    } bottom: {
                        Text("ImageView()")
                    }
                } else {
                    ImageTableView()
                }
            }
            // .overlay {
            //     if state.applicationBusy {
            //         ProgressView("Processing files...")
            //     }
            // }
        } right: {
            if alternateLayout {
                Text("MapView()")
            } else {
                SplitVView(percent: $vNormal) {
                    Text("ImageView()")
                } bottom: {
                    Text("MapView()")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .border(windowBorderColor)
        .padding()
        // .dropDestination(for: URL.self) { items, _ in
        //     let state = state
        //     Task {
        //         await state.prepareForEdit(inputURLs: items)
        //     }
        //     return true
        // }
        // .onChange(of: state.changeTimeZoneWindow) {
        //     openWindow(id: GeoTagApp.adjustTimeZone)
        // }
        .onChange(of: store.showLogWindow) {
            openWindow(id: GeoTagApp.showRunLog)
        }
        .onChange(of: store.sheetType) {
                sheetType = store.sheetType
        }
        .sheet(item: $sheetType, onDismiss: sheetDismissed) { sheet in
            sheet
        }
        .areYouSure()  // confirmations
        // .removeBackupsAlert()  // Alert: Remove Old Backup files
        // .photoLibraryEnabledAlert()
        // .photoLibraryDisabledAlert()
        // .inspector(isPresented: $state.inspectorPresented) {
        //     ImageInspectorView()
        //         .inspectorColumnWidth(min: 300, ideal: 400, max: 500)
        // }
        .onChange(of: store.importFiles) {
            importFiles.toggle()
        }
        .fileImporter(
            isPresented: $importFiles,
            allowedContentTypes: importTypes(),
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case let .success(files):
                store.send(.openFiles(files)) {
                    if let urls = store.uniqueURLs {
                        Task {
                            await images(for: urls)
                        }
                    }
                }
            case let .failure(error):
                Logger(subsystem: Bundle.main.bundleIdentifier!,
                       category: "ContentView").error(
                    "file import: \(error.localizedDescription, privacy: .public)")
            }
        }
        // .toolbar {
        //     PhotoPickerView()
        //     InspectorButtonView()
        // }
    }

    // when a sheet is dismissed check if there are more sheets to display

    private func sheetDismissed() {
        store.send(.sheetDismissed)
    }

    // the UTTypes that can be imported into this app.

    private func importTypes() -> [UTType] {
        var types: [UTType] = [.image, .folder]
        if let type = UTType(filenameExtension: "gpx") {
            types.append(type)
        }
        return types
    }

    // Create ImageData entries for imported images and add them
    // to the table.

    nonisolated private func images(for urls: [URL]) async {
        await withTaskGroup(of: ImageData?.self) { group in
            for url in urls where url.pathExtension.lowercased() != "gpx" {
                group.addTask {
                    return ImageData(from: url)
                }
            }
            for await imageData in group.compactMap({$0}) {
                await MainActor.run {
                    store.send(.addImage(imageData))
                }
            }
        }
    }
}

// AppSettings keys used to determine ContentView layout

extension ContentView {
    static let alternateLayoutKey = "AlternateLayout"
    static let splitHNormalKey = "SplitHNormalPercent"
    static let splitHAlternateKey = "SplitHAlternatePercent"
    static let splitVNormalKey = "SplitVNormalPercent"
    static let splitVAlternateKey = "SplitVAlternatePercent"
}

#Preview {
    ContentView()
        .environment(Store(initialState: GeoTagState(),
                           reduce: GeoTagReducer()))
}
