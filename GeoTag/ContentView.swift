//
//  ContentView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/9/22.
//

import SwiftUI

/// Window look and feel values
let windowBorderColor = Color.gray
let windowMinWidth = 800.0
let windowMinHeight = 800.0

struct ContentView: View {
    @EnvironmentObject var vm: ViewModel
    @ObservedObject var dividerControl = DividerControl()

    var body: some View {
        HSplitView {
            ZStack {
                ImageTableView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if vm.showingProgressView {
                    ProgressView("Processing image files...")
                }
            }
            ImageMapView(control: dividerControl)
        }
        .frame(minWidth: windowMinWidth, minHeight: windowMinHeight)
        .border(windowBorderColor)
        .padding()
        .sheet(item: $vm.sheetType, onDismiss: sheetDismissed) { sheetType in
            ContentViewSheet(type: sheetType)
        }
    }

    // clear out sheet content when the sheet is dismissed.
    func sheetDismissed() {
        vm.sheetMessage = nil
        vm.sheetError = nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ViewModel())
    }
}
