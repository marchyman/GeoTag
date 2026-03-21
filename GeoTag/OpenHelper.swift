import GpxTrackLog
import ImageData
import OSLog
import SwiftUI
import UDF

// Even though tasks are not threads trial and error shows this number
// to be a good balance between speed and user interface feedback.
private let maxConcurrentTasks = ProcessInfo.processInfo.processorCount

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
        let start = Date.now.timeIntervalSince1970
        let images = urls.filter { $0.pathExtension.lowercased() != "gpx" }
        guard !images.isEmpty else { return }

        await withTaskGroup(of: ImageData.self) { group in
            var limit = min(images.count, maxConcurrentTasks)
            for ix in 0..<limit {
                group.addTask { return ImageData(from: images[ix]) }
            }
            for await imageData in group {
                if limit < images.count {
                    let image = images[limit]
                    group.addTask { return ImageData(from: image) }
                    limit += 1
                }
                await store.send(.addImage(imageData))
            }
        }
        let duration = Date.now.timeIntervalSince1970 - start
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "OpenHelper",
               category: "OpenHelper")
            .info("""
                \(images.count, privacy: .public) images added in \
                \(duration, privacy: .public) seconds
                """)
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
            var limit = min(gpxURLs.count, maxConcurrentTasks)
            for ix in 0..<limit {
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
            for await (path, tracklog) in group {
                if limit < gpxURLs.count {
                    let url = gpxURLs[limit]
                    group.addTask {
                        do {
                            let trackLog = try GpxTrackLog(contentsOf: url)
                            return (url.path, trackLog)
                        } catch {
                            return (url.path, nil)
                        }
                    }
                    limit += 1
                }
                await store.send(.readTrackLog(path, tracklog))
            }
        }
        await store.send(.finishedAddingTracks)
    }
}
