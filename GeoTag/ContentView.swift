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
    @Environment(ContentViewModel.self) var contentViewModel
    @EnvironmentObject var avm: AppViewModel
    @Environment(\.openWindow) var openWindow

    @State private var removeOldFiles = false

    var body: some View {
        @Bindable var contentViewModel = contentViewModel
        HSplitView {
            ZStack {
                ImageTableView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if contentViewModel.showingProgressView {
                    ProgressView("Processing files...")
                }
            }
            ImageMapView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .border(windowBorderColor)
        .padding()

        // startup
        .onAppear {
            // check for a backupURL
            if !avm.doNotBackup && avm.saveBookmark == Data() {
                contentViewModel.addSheet(type: .noBackupFolderSheet)
            }
        }

        // drop destination
        .dropDestination(for: URL.self) {items, _ in
            Task {
                await avm.prepareForEdit(inputURLs: items)
            }
            return true
        }

        .onChange(of: contentViewModel.changeTimeZoneWindow) {
            openWindow(id: GeoTagApp.adjustTimeZone)
        }

        // sheets
        .sheet(item: $contentViewModel.sheetType, onDismiss: sheetDismissed) { sheet in
            sheet
        }

        // confirmations
        .confirmationDialog("Are you sure?", isPresented: $contentViewModel.presentConfirmation) {
            Button("I'm sure", role: .destructive) {
                if contentViewModel.confirmationAction != nil {
                    contentViewModel.confirmationAction!()
                }
            }
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.defaultAction)
        } message: {
            let message = contentViewModel.confirmationMessage != nil ? contentViewModel.confirmationMessage! : ""
            Text(message)
        }

        // Alert: Remove Old Backup files
        .alert("Delete old backup files?", isPresented: $contentViewModel.removeOldFiles) {
            Button("Delete", role: .destructive) {
                avm.remove(filesToRemove: contentViewModel.oldFiles)
            }
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.defaultAction)
        } message: {
            // swiftlint:disable line_length
            Text("""
                 Your current backup/save folder

                     \(avm.backupURL != nil ? avm.backupURL!.path : "unknown")

                 is using \(contentViewModel.folderSize / 1_000_000) MB to store backup files.

                 \(contentViewModel.oldFiles.count) files using \(contentViewModel.deletedSize / 1_000_000) MB of storage were placed in the folder more than 7 days ago.

                 Would you like to remove those \(contentViewModel.oldFiles.count) backup files?
                 """)
            // swiftlint:enable line_length
        }
    }

    // when a sheet is dismissed check if there are more sheets to display

    func sheetDismissed() {
        if contentViewModel.sheetStack.isEmpty {
            contentViewModel.sheetMessage = nil
            contentViewModel.sheetError = nil
        } else {
            let sheetInfo = contentViewModel.sheetStack.removeFirst()
            contentViewModel.sheetMessage = sheetInfo.sheetMessage
            contentViewModel.sheetError = sheetInfo.sheetError
            contentViewModel.sheetType = sheetInfo.sheetType
        }
    }

}

#Preview {
    ContentView()
        .environment(ContentViewModel.shared)
        .environmentObject(AppViewModel(forPreview: true))
}
