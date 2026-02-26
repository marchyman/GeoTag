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

    @State private var sheetType: SheetType?
    @State private var importFiles = false
    @State private var spinnerEnabled = false
    @State private var inspectorPresented = false

    var body: some View {
        SplitHView(percent: alternateLayout ? $hAlternate : $hNormal) {
            Group {
                if alternateLayout {
                    SplitVView(percent: $vAlternate) {
                        ImageTableView(inspectorPresented: $inspectorPresented)
                    } bottom: {
                        ImageView()
                    }
                } else {
                    ImageTableView(inspectorPresented: $inspectorPresented)
                }
            }
            .overlay {
                if spinnerEnabled {
                    ProgressView("Processing files...")
                }
            }
        } right: {
            if alternateLayout {
                MapWithSearchView()
            } else {
                SplitVView(percent: $vNormal) {
                    ImageView()
                } bottom: {
                    MapWithSearchView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .border(windowBorderColor)
        .padding()
        .dropDestination(for: URL.self) { items, _ in
            spinnerEnabled = true
            store.send(.openFiles(items), undoable: false) {
                if let urls = store.uniqueURLs {
                    OpenHelper.open(store, urls: urls,
                                    description: "drag files",
                                    spinnerEnabled: $spinnerEnabled)
                } else {
                    spinnerEnabled = false
                }
            }
            return true
        }
        .onChange(of: store.showTimeZoneWindow) {
            openWindow(id: GeoTagApp.adjustTimeZone)
        }
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
        .removeBackupsAlert()  // Alert: Remove Old Backup files
        .inspector(isPresented: $inspectorPresented) {
            ImageInspectorView()
                .inspectorColumnWidth(min: 300, ideal: 400, max: 500)
        }
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
                spinnerEnabled = true
                store.send(.openFiles(files), undoable: false) {
                    if let urls = store.uniqueURLs {
                        OpenHelper.open(store, urls: urls,
                                        description: "add files",
                                        spinnerEnabled: $spinnerEnabled)
                    } else {
                        spinnerEnabled = false
                    }
                }
            case let .failure(error):
                Logger(subsystem: Bundle.main.bundleIdentifier!,
                       category: "ContentView").error(
                    "file import: \(error.localizedDescription, privacy: .public)")
            }
        }
        .toolbar {
            PhotoPickerView()
            InspectorButtonView(presented: $inspectorPresented)
        }
    }

    // when a sheet is dismissed check if there are more sheets to display

    private func sheetDismissed() {
        store.send(.sheetDismissed, undoable: false)
    }

    // the UTTypes that can be imported into this app.

    private func importTypes() -> [UTType] {
        var types: [UTType] = [.image, .folder]
        if let type = UTType(filenameExtension: "gpx") {
            types.append(type)
        }
        return types
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

#Preview(traits: .store) {
    ContentView()
        .frame(width: 800, height: 1000)
}

#Preview("selected", traits: .select(9, 10)) {
    ContentView()
        .frame(width: 800, height: 1000)
}
