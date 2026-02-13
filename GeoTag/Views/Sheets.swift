import SwiftUI
import UDF

// sheet size
let sheetWidth = 600.0
let sheetMinHeight = 400.0

// types of sheets that may be attached to the content view

enum SheetType: Identifiable, View {
    case gpxFileNameSheet
    case duplicateImageSheet
    case noBackupFolderSheet
    case savingUpdatesSheet
    // case saveErrorSheet
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
        // case .saveErrorSheet:
        //     SaveErrorView().withDismiss()
        case .unexpectedErrorSheet:
            UnexpectedErrorView().withDismiss()
        }
    }
}

// show lists of GPX files that were loaded or failed to load
// Load failure occurs when a file with the extension of .gpx failed to parse as a valid GPX file

struct GpxLoadView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    var body: some View {
        VStack(alignment: .leading) {
            if store.gpxGoodFileNames.count > 0 {
                Text("GPX Files Loaded")
                    .font(.title)
                List(store.gpxGoodFileNames, id: \.self) { Text($0) }
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
            if store.gpxBadFileNames.count > 0 {
                Text("GPX Files NOT Loaded")
                    .font(.title)
                List(store.gpxBadFileNames, id: \.self) { Text($0) }
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
            store.send(.gpxLoadViewClosed)
            store.discardUndo()
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

// struct SaveErrorView: View {
//     @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
//
//     var body: some View {
//         VStack {
//             Text("One or more files could not be saved")
//                 .font(.title)
//                 .padding()
//             Text("The updates to one or more files could not be updated.")
//                 .lineLimit(nil)
//                 .padding(.bottom, 40)
//             List {
//                 ForEach(store.saveIssues.sorted(by: >), id: \.key) { key, value in
//                     VStack(alignment: .leading) {
//                         Text(key.lastPathComponent)
//                             .bold()
//                         Text(value)
//                             .padding(.bottom)
//                     }
//                 }
//             }
//             .frame(maxHeight: .infinity)
//         }
//         .frame(maxWidth: 600, minHeight: 400)
//     }
//
// }

struct UnexpectedErrorView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    var body: some View {
        VStack {
            Text("Unexpected Error")
                .font(.title)
                .padding()
            if let message = store.sheetMessage {
                Text(message)
                    .padding()
            }
            if let errorDescription = store.sheetError {
                Text(errorDescription)
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
    let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
    // swiftlint:disable:next redundant_discardable_let
    let _ = store.send(.goodGpxFile("Good/File/Name"))
    SheetType.gpxFileNameSheet
        .environment(store)
}

#Preview("GpxLoadView (bad)") {
    let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
    // swiftlint:disable:next redundant_discardable_let
    let _ = store.send(.badGpxFile("Bad/File/Name"))
    SheetType.gpxFileNameSheet
        .environment(store)
}

#Preview("GpxLoadView (both)") {
    let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
    // swiftlint:disable redundant_discardable_let
    let _ = store.send(.goodGpxFile("Good/File/Name"))
    let _ = store.send(.badGpxFile("Bad/File/Name"))
    // swiftlint:enable redundant_discardable_let
    SheetType.gpxFileNameSheet
        .environment(store)
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

// #Preview("SaveErrorView") {
//     let store = Store(GeoTagState(), GeoTagReducer())
//     store.saveIssues[URL(fileURLWithPath: "/path/to/some/image.jpg")] = "some save error"
//     store.saveIssues[URL(fileURLWithPath: "/path/to/some/other.jpg")] = "some other error"
//     return SheetType.saveErrorSheet
//         .environment(store)
// }
