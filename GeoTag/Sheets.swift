//
//  Sheets.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/14/22.
//

import SwiftUI

/// sheet size
let sheetMinWidth = 600.0
let sheetMinHeight = 400.0

/// types of sheets that may be attached to the content view
enum SheetType: Identifiable {
    var id: Self {
        return self
    }

    case gpxFileNameSheet
    case saveChangesSheet
}

/// select a view depending upon the current app state sheet type
struct ContentViewSheet: View {
    var type: SheetType

    var body: some View {
        switch type {
        case .gpxFileNameSheet:
            GpxLoadView()
        case .saveChangesSheet:
            EmptyView()
        }
    }
}

/// show lists of GPX files that were loaded or failed to load
/// Load failure occurs when a file with the extension of .gpx failed to parse as a valid GPX file
struct GpxLoadView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Dismiss") {
                    dismiss()
                }
            }
            if (appState.gpxGoodFileNames.count > 0) {
                Text("GPX Files Loaded")
                List (appState.gpxGoodFileNames, id: \.self) { Text($0) }
            }
            if (appState.gpxBadFileNames.count > 0) {
                Text("Bad GPX Files NOT Loaded")
                List (appState.gpxBadFileNames, id: \.self) { Text($0) }
            }
        }
        .frame(minWidth: sheetMinWidth, minHeight: sheetMinHeight)
        .padding()
    }
}
