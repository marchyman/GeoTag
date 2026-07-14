import OSLog
import SplitHView
import SplitVView
import SwiftUI
import UDF
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
    @Environment(\.openWindow) var openWindow

    @AppStorage(Self.alternateLayoutKey) var alternateLayout = false

    @State private var sheetType: SheetType?
    @State private var importFiles = false
    @State private var spinnerEnabled = false
    @State private var inspectorPresented = false

    private let testIDs = TestIDs.ContentView.self

    var body: some View {
        Group {
            if alternateLayout {
                Layout2(inspectorPresented: $inspectorPresented,
                        spinnerEnabled: $spinnerEnabled)
            } else {
                Layout1(inspectorPresented: $inspectorPresented,
                        spinnerEnabled: $spinnerEnabled)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .dropDestination(for: URL.self) { items, _ in
            store.send(.openFiles(items), undoable: false) {
                if let urls = store.uniqueURLs {
                    OpenHelper.open(store, urls: urls,
                                    description: "drag files",
                                    spinnerEnabled: $spinnerEnabled)
                    store.send(.clearUniqueURLs)
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
                .accessibilityIdentifier(testIDs.imageInspectorViewID)
        }
        .onChange(of: store.importFiles) {
            importFiles.toggle()
        }
        .fileImporter(isPresented: $importFiles,
                      allowedContentTypes: importTypes(),
                      allowsMultipleSelection: true) { result in
            switch result {
            case let .success(files):
                store.send(.openFiles(files), undoable: false) {
                    if let urls = store.uniqueURLs {
                        OpenHelper.open(store, urls: urls,
                                        description: "add files",
                                        spinnerEnabled: $spinnerEnabled)
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
                .accessibilityIdentifier(testIDs.photoPickerViewID)
            InspectorButtonView(presented: $inspectorPresented)
                .accessibilityIdentifier(testIDs.inspectorButtonViewID)
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

extension ContentView {
    static let alternateLayoutKey = "AlternateLayout"
}

#Preview(traits: .store) {
    ContentView()
        .frame(width: 800, height: 1000)
}
