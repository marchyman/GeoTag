//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

// sheet size
let sheetWidth = 600.0
let sheetMinHeight = 400.0

// types of sheets that may be attached to the content view

enum SheetType: Identifiable, View {
    case gpxFileNameSheet
    case duplicateImageSheet
    case noBackupFolderSheet
    case savingUpdatesSheet
    case saveErrorSheet
    case unexpectedErrorSheet

    nonisolated var id: Self {
        return self
    }

    var body: some View {
        switch self {
        case .gpxFileNameSheet:
            GpxLoadView().withDismiss()
        case .duplicateImageSheet:
            DuplicateImageView().withDismiss()
        case .noBackupFolderSheet:
            NoBackupFolderView().withDismiss()
        case .savingUpdatesSheet:
            SavingUpdatesView().withDismiss()
        case .saveErrorSheet:
            SaveErrorView().withDismiss()
        case .unexpectedErrorSheet:
            UnexpectedErrorView().withDismiss()
        }
    }
}

// show lists of GPX files that were loaded or failed to load
// Load failure occurs when a file with the extension of .gpx failed to parse as a valid GPX file

struct GpxLoadView: View {
    @Environment(AppState.self) var state

    var body: some View {
        VStack(alignment: .leading) {
            if state.gpxGoodFileNames.count > 0 {
                Text("GPX Files Loaded")
                    .font(.title)
                List(state.gpxGoodFileNames, id: \.self) { Text($0) }
                    .frame(maxHeight: .infinity)
                Text(
                    """
                    The above GPX file(s) have been processed and will \
                    show as tracks on the map.
                    """
                )
                .lineLimit(nil)
                .padding()
            }
            if state.gpxBadFileNames.count > 0 {
                Text("GPX Files NOT Loaded")
                    .font(.title)
                List(state.gpxBadFileNames, id: \.self) { Text($0) }
                    .frame(maxHeight: .infinity)
                Text("No valid tracks found in above GPX file(s).")
                    .font(.title)
                    .padding()
                Text(
                    """
                    Either no tracks could be found or the GPX file was \
                    corrupted such that it could not be properly processed. \
                    Any track log information in the file has been ignored.
                    """
                )
                .lineLimit(nil)
                .padding([.leading, .bottom, .trailing])
            }
        }
        .onDisappear {
            // clear lists of good and bad track file names
            state.gpxGoodFileNames = []
            state.gpxBadFileNames = []
        }
        .frame(
            minWidth: sheetWidth, maxWidth: sheetWidth,
            minHeight: sheetMinHeight)
    }
}

struct DuplicateImageView: View {
    var body: some View {
        VStack {
            Text("One or more files not opened")
                .font(.title)
                .padding()
            Text(
                """
                One or more files were not opened. Unopened files were \
                duplicates of files previously opened for editing.
                """
            )
            .lineLimit(nil)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: 400, minHeight: 100)
    }

}

struct NoBackupFolderView: View {
    var body: some View {
        VStack {
            Text("Image backup folder can not be found")
                .font(.title)
                .padding()
            Text(
                """
                Image backups are enabled but no backup folder is \
                specified or the specified folder can no longer be found. \
                Please open the program settings window (⌘ ,) and select \
                a folder for image backups.
                """
            )
            .lineLimit(nil)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: 400, minHeight: 200)
    }

}
struct SavingUpdatesView: View {
    var body: some View {
        VStack {
            Text("Save in progress")
                .font(.title)
                .padding()
            Text(
                """
                Image updates are still being processed.  Please wait \
                for the updates to complete before quiting GeoTag.
                """
            )
            .lineLimit(nil)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: 400, minHeight: 100)
    }
}

struct SaveErrorView: View {
    @Environment(AppState.self) var state

    var body: some View {
        VStack {
            Text("One or more files could not be saved")
                .font(.title)
                .padding()
            Text("The updates to one or more files could not be updated.")
                .lineLimit(nil)
                .padding(.bottom, 40)
            List {
                ForEach(state.saveIssues.sorted(by: >), id: \.key) { key, value in
                    VStack(alignment: .leading) {
                        Text(key.lastPathComponent)
                            .bold()
                        Text(value)
                            .padding(.bottom)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: 600, minHeight: 400)
    }

}

struct UnexpectedErrorView: View {
    @Environment(AppState.self) var state

    var body: some View {
        VStack {
            Text("Unexpected Error")
                .font(.title)
                .padding()
            if let message = state.sheetMessage {
                Text(message)
                    .padding()
            }
            if let error = state.sheetError {
                Text(error.localizedDescription)
                    .padding()
            }
        }
        .lineLimit(nil)
        .frame(maxWidth: 400, minHeight: 100, maxHeight: .infinity)
    }

}

// Add a dismiss button to the top of the given content.

struct DismissModifier: ViewModifier {
    @Environment(\.dismiss) var dismiss

    func body(content: Content) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button("Dismiss") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
    }
}

extension View {
    func withDismiss() -> some View {
        self.modifier(DismissModifier())
    }
}

// MARK: Previews

#Preview("GpxLoadView") {
    let state = AppState()
    state.gpxGoodFileNames.append("Good/File/Name")
    return SheetType.gpxFileNameSheet
        .environment(state)
}

#Preview("GpxLoadView (bad)") {
    let state = AppState()
    state.gpxBadFileNames.append("Bad/File/Name")
    return SheetType.gpxFileNameSheet
        .environment(state)
}

#Preview("GpxLoadView (both)") {
    let state = AppState()
    state.gpxGoodFileNames.append("Good/File/Name")
    state.gpxBadFileNames.append("Bad/File/Name")
    return SheetType.gpxFileNameSheet
        .environment(state)
}

#Preview("DuplicateImageView") {
    SheetType.duplicateImageSheet
}

#Preview("NoBackupFolderView") {
    SheetType.noBackupFolderSheet
}

#Preview("SavingUpdatesView") {
    SheetType.savingUpdatesSheet
}

#Preview("SaveErrorView") {
    let state = AppState()
    state.saveIssues[URL(fileURLWithPath: "/path/to/some/image.jpg")] = "some save error"
    state.saveIssues[URL(fileURLWithPath: "/path/to/some/other.jpg")] = "some other error"
    return SheetType.saveErrorSheet
        .environment(state)
}
