//
//  ContentView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/9/22.
//

import SwiftUI
import UniformTypeIdentifiers

/// Window look and feel values
let windowBorderColor = Color.gray

struct ContentView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
    @AppStorage(AppSettings.savedBookmarkKey) var savedBookmark = Data()
    @AppStorage(AppSettings.splitHContentKey) var hPercent = 0.45

    @State private var removeOldFiles = false

    var body: some View {
        @Bindable var state = state
        SplitHView(percent: $hPercent) {
            ImageTableView(tvm: state.tvm)
                .overlay {
                    if state.applicationBusy {
                        ProgressView("Processing files...")
                    }
                }
        } right: {
            ImageMapView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .border(windowBorderColor)
        .padding()
        .onAppear {
            // check for a backupURL
            if !doNotBackup && savedBookmark == Data() {
                state.addSheet(type: .noBackupFolderSheet)
            }
        }
        .dropDestination(for: URL.self) {items, _ in
            let state = state
            Task.detached {
                await state.prepareForEdit(inputURLs: items)
            }
            return true
        }
        .onChange(of: state.changeTimeZoneWindow) {
            openWindow(id: GeoTagApp.adjustTimeZone)
        }
        .sheet(item: $state.sheetType, onDismiss: sheetDismissed) { sheet in
            sheet
        }
        .areYouSure()                       // confirmations
        .removeBackupsAlert()               // Alert: Remove Old Backup files
        .inspector(isPresented: $state.inspectorPresented) {
            ImageInspectorView()
                .inspectorColumnWidth(min: 300, ideal: 400, max: 500)
        }
        .fileImporter(isPresented: $state.importFiles,
                      allowedContentTypes: importTypes(),
                      allowsMultipleSelection: true) { result in
            switch result {
            case .success(let files):
                importFiles(files)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        .toolbar {
            PhotoPickerView()
            InspectorButtonView()
        }

    }

    // when a sheet is dismissed check if there are more sheets to display

    private func sheetDismissed() {
        if state.sheetStack.isEmpty {
            state.sheetMessage = nil
            state.sheetError = nil
        } else {
            let sheetInfo = state.sheetStack.removeFirst()
            state.sheetMessage = sheetInfo.sheetMessage
            state.sheetError = sheetInfo.sheetError
            state.sheetType = sheetInfo.sheetType
        }
    }

    // the UTTypes that can be imported into this app.

    private func importTypes() -> [UTType] {
        var types: [UTType] = [.image, .folder]
        if let type = UTType(filenameExtension: "gpx") {
            types.append(type)
        }
        return types
    }

    private func importFiles(_ urls: [URL]) {
        let state = state
        Task.detached {
            state.startSecurityScoping(urls: urls)
            await state.prepareForEdit(inputURLs: urls)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
