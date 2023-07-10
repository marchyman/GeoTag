//
//  ContentView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/9/22.
//

import SwiftUI

/// Window look and feel values
let windowBorderColor = Color.gray

struct ContentView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
    @AppStorage(AppSettings.savedBookmarkKey) var savedBookmark = Data()

    @State private var removeOldFiles = false

    var body: some View {
        @Bindable var state = state
        HSplitView {
            ZStack {
                ImageTableView(tvm: state.tvm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if state.applicationBusy {
                    ProgressView("Processing files...")
                }
            }
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
            Task {
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

    }

    // when a sheet is dismissed check if there are more sheets to display

    func sheetDismissed() {
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

}

#Preview {
    ContentView()
        .environment(AppState())
}
