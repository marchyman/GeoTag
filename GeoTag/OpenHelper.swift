import GpxTrackLog
import ImageData
import SwiftUI
import UDF

private let maxConcurrentTasks = 8  // adjust to taste

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
        let images = urls.filter { $0.pathExtension.lowercased() != "gpx" }
        guard !images.isEmpty else { return }

        await withTaskGroup(of: ImageData.self) { group in
            let maxTasks = min(images.count, maxConcurrentTasks)
            for ix in 0..<maxTasks {
                group.addTask { return await ImageData(from: images[ix]) }
            }
            var nextIx = maxTasks
            for await imageData in group {
                if nextIx < images.count {
                    let image = images[nextIx]
                    group.addTask { return await ImageData(from: image) }
                    nextIx += 1
                }
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
            let maxTasks = min(gpxURLs.count, maxConcurrentTasks)
            for ix in 0..<maxTasks {
                let url = gpxURLs[ix]
                group.addTask {
                    do {
                        let trackLog = try GpxTrackLog(contentsOf: url)
                        return (url.path, trackLog)
                    } catch {
                        return (url.path, nil)
                    }
                }
            }
            var nextIx = maxTasks
            for await (path, tracklog) in group {
                if nextIx < gpxURLs.count {
                    let url = gpxURLs[nextIx]
                    group.addTask {
                        do {
                            let trackLog = try GpxTrackLog(contentsOf: url)
                            return (url.path, trackLog)
                        } catch {
                            return (url.path, nil)
                        }
                    }
                    nextIx += 1
                }
                await store.send(.readTrackLog(path, tracklog))
            }
        }
        await store.send(.finishedAddingTracks)
    }
}
