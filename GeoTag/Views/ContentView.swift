//
// Copyright 2022 Marco S Hyman
// https://www.snafu.org/
//

import SplitHView
import SplitVView
import SwiftUI
import UDF
import UniformTypeIdentifiers

/// Window look and feel values
let windowBorderColor = Color.gray

struct ContentView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
    // @Environment(\.openWindow) var openWindow
    //
    @AppStorage(Self.alternateLayoutKey) var alternateLayout = false
    // @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
    // @AppStorage(AppSettings.savedBookmarkKey) var savedBookmark = Data()
    @AppStorage(Self.splitHNormalKey) var hNormal = 0.45
    @AppStorage(Self.splitHAlternateKey) var hAlternate = 0.55
    @AppStorage(Self.splitVNormalKey) var vNormal = 0.60
    @AppStorage(Self.splitVAlternateKey) var vAlternate = 0.40
    //
    // @State private var removeOldFiles = false

    var body: some View {
        SplitHView(percent: alternateLayout ? $hAlternate : $hNormal) {
            Group {
                if alternateLayout {
                    SplitVView(percent: $vAlternate) {
                        Text("ImageTableView(tvm: state.tvm)")
                    } bottom: {
                        Text("ImageView()")
                    }
                } else {
                    Text("ImageTableView(tvm: state.tvm)")
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
        // .onAppear {
        //     // check for a backupURL. Once when this window appears.
        //     if !state.initialBackupURLCheck
        //             && !doNotBackup && savedBookmark == Data() {
        //         state.initialBackupURLCheck = true
        //         state.addSheet(type: .noBackupFolderSheet)
        //     }
        // }
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
        // .onChange(of: state.showLogWindow) {
        //     openWindow(id: GeoTagApp.showRunLog)
        // }
        // .sheet(item: $state.sheetType, onDismiss: sheetDismissed) { sheet in
        //     sheet
        // }
        // .areYouSure()  // confirmations
        // .removeBackupsAlert()  // Alert: Remove Old Backup files
        // .photoLibraryEnabledAlert()
        // .photoLibraryDisabledAlert()
        // .inspector(isPresented: $state.inspectorPresented) {
        //     ImageInspectorView()
        //         .inspectorColumnWidth(min: 300, ideal: 400, max: 500)
        // }
        // .fileImporter(
        //     isPresented: $state.importFiles,
        //     allowedContentTypes: importTypes(),
        //     allowsMultipleSelection: true
        // ) { result in
        //     switch result {
        //     case .success(let files):
        //         importFiles(files)
        //     case .failure(let error):
        //         AppState.logger.error(
        //             "file import: \(error.localizedDescription, privacy: .public)")
        //     }
        // }
        // .toolbar {
        //     PhotoPickerView()
        //     InspectorButtonView()
        // }
    }

    // when a sheet is dismissed check if there are more sheets to display

    // private func sheetDismissed() {
    //     if state.sheetStack.isEmpty {
    //         state.sheetMessage = nil
    //         state.sheetError = nil
    //     } else {
    //         let sheetInfo = state.sheetStack.removeFirst()
    //         state.sheetMessage = sheetInfo.sheetMessage
    //         state.sheetError = sheetInfo.sheetError
    //         state.sheetType = sheetInfo.sheetType
    //     }
    // }

    // the UTTypes that can be imported into this app.

    private func importTypes() -> [UTType] {
        var types: [UTType] = [.image, .folder]
        if let type = UTType(filenameExtension: "gpx") {
            types.append(type)
        }
        return types
    }

    // private func importFiles(_ urls: [URL]) {
    //     Task {
    //         state.startSecurityScoping(urls: urls)
    //         await state.prepareForEdit(inputURLs: urls)
    //     }
    // }
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
