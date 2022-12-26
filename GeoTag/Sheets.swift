//
//  Sheets.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/14/22.
//

import SwiftUI

/// sheet size
let sheetWidth = 600.0
let sheetMinHeight = 400.0

/// types of sheets that may be attached to the content view
enum SheetType: Identifiable {
    var id: Self {
        return self
    }

    case gpxFileNameSheet
    case saveChangesSheet
    case duplicateImageSheet
    case unexpectedErrorSheet
}

/// select a view depending upon the current app state sheet type
struct ContentViewSheet: View {
    @Environment(\.dismiss) private var dismiss

    var type: SheetType

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button("Dismiss") {
                    dismiss()
                }
            }
            switch type {
            case .gpxFileNameSheet:
                GpxLoadView()
            case .saveChangesSheet:
                EmptyView()
            case .duplicateImageSheet:
                DuplicateImageView()
            case .unexpectedErrorSheet:
                UnexpectedErrorView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
    }
}

/// show lists of GPX files that were loaded or failed to load
/// Load failure occurs when a file with the extension of .gpx failed to parse as a valid GPX file
struct GpxLoadView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading) {
            if (appState.gpxGoodFileNames.count > 0) {
                Text("GPX Files Loaded")
                    .font(.title)
                List (appState.gpxGoodFileNames, id: \.self) { Text($0) }
                    .frame(maxHeight: .infinity)
                Text("The above GPX file(s) have been processed and will show as tracks on the map.")
                    .lineLimit(nil)
                    .padding()
            }
            if (appState.gpxBadFileNames.count > 0) {
                Text("GPX Files NOT Loaded")
                    .font(.title)
                List (appState.gpxBadFileNames, id: \.self) { Text($0) }
                    .frame(maxHeight: .infinity)
                Text("No valid tracks found in above GPX file(s).")
                    .font(.title)
                    .padding()
                Text("Either no tracks could be found or the GPX file was corrupted such that it could not be properly processed. Any track log information in the file has been ignored.")
                    .lineLimit(nil)
                    .padding([.leading, .bottom, .trailing])
            }
        }
        .frame(minWidth: sheetWidth, maxWidth: sheetWidth,
               minHeight: sheetMinHeight)
    }
}

struct DuplicateImageView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack() {
            Text("One or more files not opened")
                .font(.title)
                .padding()
            Text("One or more files were not opened. Unopened files were duplicates of files previously opened for editing.")
                .lineLimit(nil)
        }
        .frame(maxWidth: 400, minHeight: 100)
    }

}

struct UnexpectedErrorView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack() {
            Text("Unexpected Error")
                .font(.title)
                .padding()
            if let message = appState.sheetMessage {
                Text(message)
                    .lineLimit(nil)
                    .padding()
            }
            if let error = appState.sheetError {
                Text(error.localizedDescription)
                    .lineLimit(nil)
                    .padding()
            }
        }
        .frame(maxWidth: 400, minHeight: 100)
    }

}
