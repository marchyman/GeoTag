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
    @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
    @AppStorage(AppSettings.saveBookmarkKey) var saveBookmark = Data()

    @EnvironmentObject var vm: ViewModel
    @State private var sheetType: SheetType?
    @State private var presentConfirmation = false
    @State private var removeOldFiles = false

    var body: some View {
        HSplitView {
            ZStack {
                ImageTableView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if vm.showingProgressView {
                    ProgressView("Processing image files...")
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
            if !doNotBackup && saveBookmark == Data() {
                vm.addSheet(type: .noBackupFolderSheet)
            }
        }

        // sheets
        .sheet(item: $sheetType, onDismiss: sheetDismissed) { sheet in
            sheet
        }
        .link($vm.sheetType, with: $sheetType)

        // confirmations
        .confirmationDialog("Are you sure?", isPresented: $presentConfirmation) {
            Button("I'm sure", role: .destructive) {
                if vm.confirmationAction != nil {
                    vm.confirmationAction!()
                }
            }
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.defaultAction)
        } message: {
            let message = vm.confirmationMessage != nil ? vm.confirmationMessage! : ""
            Text(message)
        }
        .link($vm.presentConfirmation, with: $presentConfirmation)

        // Alert: Remove Old Backup files
        .alert("Delete old backup files?",
               isPresented: $removeOldFiles) {
            Button("Delete", role: .destructive) {
                vm.remove(filesToRemove: vm.oldFiles)
            }
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.defaultAction)
        } message: {
            Text("""
                 Your current backup/save folder

                     \(vm.backupURL != nil ? vm.backupURL!.path : "unknown")

                 is using \(vm.folderSize / 1_000_000) MB to store backup files.

                 \(vm.oldFiles.count) files using \(vm.deletedSize / 1_000_000) MB of storage were placed in the folder more than 7 days ago.

                 Would you like to remove those \(vm.oldFiles.count) backup files?
                 """)
        }
        .link($vm.removeOldFiles, with: $removeOldFiles)
    }

    // when a sheet is dismissed check if there are more sheets to display

    func sheetDismissed() {
        if vm.sheetStack.isEmpty {
            vm.sheetMessage = nil
            vm.sheetError = nil
        } else {
            let sheetInfo = vm.sheetStack.removeFirst()
            vm.sheetMessage = sheetInfo.sheetMessage
            vm.sheetError = sheetInfo.sheetError
            vm.sheetType = sheetInfo.sheetType
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
            .environmentObject(ViewModel())
    }
}
