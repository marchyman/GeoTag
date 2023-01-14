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
    @EnvironmentObject var vm: ViewModel

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

        // sheets
        .sheet(item: $vm.sheetType, onDismiss: sheetDismissed) { sheetType in
            ContentViewSheet(type: sheetType)
        }

        // confirmations
        .confirmationDialog("Are you sure?", isPresented: $vm.presentConfirmation) {
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

        // Alert: Remove Old Backup files
        .alert("Delete old backup files?",
               isPresented: $vm.removeOldFiles) {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ViewModel())
    }
}
