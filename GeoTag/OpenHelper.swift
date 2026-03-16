import GpxTrackLog
import ImageData
import SwiftUI
import UDF

@MainActor
enum OpenHelper {
    @MainActor
    @discardableResult
    static func open(_ store: Store<GeoTagState, GeoTagEvent>, urls: [URL],
                     description: String,
                     spinnerEnabled: Binding<Bool>?) -> Task<Void, Never> {
        let task = Task { @MainActor in
            store.beginUndoGroup(description: description)
            await Self.images(for: urls, store: store)
            await Self.tracks(for: urls, store: store)
            if let spinnerEnabled {
                spinnerEnabled.wrappedValue = false
            }
            store.endUndoGroup()
        }
        return task
    }

    // Create ImageData entries for imported images and add them
    // to the table.

    static nonisolated private func images(for urls: [URL],
                                           store: Store<GeoTagState, GeoTagEvent>) async {
        await withTaskGroup(of: ImageData.self) { group in
            for url in urls where url.pathExtension.lowercased() != "gpx" {
                group.addTask {
                    return ImageData(from: url)
                }
            }
            for await imageData in group {
                await store.send(.addImage(imageData))
            }
        }
        await MainActor.run {
            @AppStorage(SettingsView.disablePairedJpegsKey) var disablePairedJpegs = false

            store.send(.linkPairedImages(disablePairedJpegs))
            store.send(.sortUsingCurrentComparator)
        }
    }

    static nonisolated private func tracks(for urls: [URL],
                                           store: Store<GeoTagState, GeoTagEvent>) async {
        let gpxURLs = urls.filter { $0.pathExtension.lowercased() == "gpx" }
        guard !gpxURLs.isEmpty else { return }

        await withTaskGroup(of: (String, GpxTrackLog?).self) { group in
            for url in gpxURLs {
                group.addTask {
                    do {
                        let trackLog = try GpxTrackLog(contentsOf: url)
                        return (url.path, trackLog)
                    } catch {
                        return (url.path, nil)
                    }
                }
            }
            for await (path, tracklog) in group {
                await store.send(.readTrackLog(path, tracklog))
            }
        }
        await store.send(.finishedAddingTracks)
    }
}
