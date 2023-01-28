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
    @EnvironmentObject var vm: AppViewModel
    @ObservedObject var contentViewModel = ContentViewModel.shared

    @State private var sheetType: SheetType?
    @State private var presentConfirmation = false
    @State private var removeOldFiles = false

    var body: some View {
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
            if !vm.doNotBackup
                && vm.saveBookmark == Data() {
                contentViewModel.addSheet(type: .noBackupFolderSheet)
            }
        }

        // sheets
        .sheet(item: $sheetType, onDismiss: sheetDismissed) { sheet in
            sheet
        }
        .link($contentViewModel.sheetType, with: $sheetType)

        // confirmations
        .confirmationDialog("Are you sure?", isPresented: $presentConfirmation) {
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
        .link($contentViewModel.presentConfirmation, with: $presentConfirmation)

        // Alert: Remove Old Backup files
        .alert("Delete old backup files?", isPresented: $removeOldFiles) {
            Button("Delete", role: .destructive) {
                vm.remove(filesToRemove: contentViewModel.oldFiles)
            }
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.defaultAction)
        } message: {
            Text("""
                 Your current backup/save folder

                     \(vm.backupURL != nil ? vm.backupURL!.path : "unknown")

                 is using \(contentViewModel.folderSize / 1_000_000) MB to store backup files.

                 \(contentViewModel.oldFiles.count) files using \(contentViewModel.deletedSize / 1_000_000) MB of storage were placed in the folder more than 7 days ago.

                 Would you like to remove those \(contentViewModel.oldFiles.count) backup files?
                 """)
        }
        .link($contentViewModel.removeOldFiles, with: $removeOldFiles)
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

// SwiftUI sometimes has issues when a published variabe in an ObservedObject
// or EnvironmentObject is bound in a view.  Perhaps this is a SwiftUI bug.
// This extension on View links a Published variables to a local state variable
// to work around the problem.

extension View {
    func link<T: Equatable>(_ published: Binding<T>,
                            with binding: Binding<T>) -> some View {
        self
            .onChange(of: published.wrappedValue) { published in
                binding.wrappedValue = published
            }
            .onChange(of: binding.wrappedValue) { binding in
                published.wrappedValue = binding
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppViewModel())
    }
}
