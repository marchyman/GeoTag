import GpxTrackLog
import ImageData
import OSLog
import SwiftUI
import UDF

enum OpenHelper {

    static let logger =
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
               category: "OpenHelper")

    // Start a mainactor task to process image and track files. The
    // task is returned so code tests can wait until the task is complete.

    @MainActor
    @discardableResult
    static func open(_ store: Store<GeoTagState, GeoTagEvent>, urls: [URL],
                     description: String,
                     spinnerEnabled: Binding<Bool>?) -> Task<Void, Never> {
        let task = Task { @MainActor in
            if let spinnerEnabled {
                spinnerEnabled.wrappedValue = true
            }
            store.beginUndoGroup(description: description)
            await Self.images(for: urls, store: store)
            await Self.tracks(for: urls, store: store)
            store.endUndoGroup()
            if let spinnerEnabled {
                spinnerEnabled.wrappedValue = false
            }
        }
        return task
    }

    // Create ImageData entries for imported images and add them
    // to the table.

    static private func images(for urls: [URL],
                               store: Store<GeoTagState, GeoTagEvent>) async {
        let images = urls.filter { $0.pathExtension.lowercased() != "gpx" }
        guard !images.isEmpty else { return }
        let start = Date.now.timeIntervalSince1970

        await withTaskGroup(of: ImageData.self) { group in
            var limit = min(images.count, GeoTagApp.maxConcurrentTasks)
            for ix in 0..<limit {
#if DEBUG
                Self.logger.debug("\(images[ix].path) begin")
#endif
                group.addTask { return ImageData(from: images[ix]) }
            }
            for await imageData in group {
                if limit < images.count {
                    let image = images[limit]
#if DEBUG
                    Self.logger.debug("\(image.path) begin")
#endif
                    limit += 1
                    group.addTask { return ImageData(from: image) }
                }
#if DEBUG
                let path = switch imageData.metadata.source {
                case .image(let url):
                    url.path
                case .xmp(let url):
                    url.path
                default:
                    "unknown"
                }
                Self.logger.debug("\(path) end")
#endif
                await store.send(.addImage(imageData))
            }
        }
        await MainActor.run {
            @AppStorage(SettingsView.disablePairedJpegsKey) var disablePairedJpegs = false

            store.send(.linkPairedImages(disablePairedJpegs))
            store.send(.sortUsingCurrentComparator)
        }
        let duration = Date.now.timeIntervalSince1970 - start
        Self.logger.info("""
            \(images.count, privacy: .public) images added in \
            \(duration, privacy: .public) seconds
            """)
    }

    static private func tracks(for urls: [URL],
                               store: Store<GeoTagState, GeoTagEvent>) async {
        let gpxURLs = urls.filter { $0.pathExtension.lowercased() == "gpx" }
        guard !gpxURLs.isEmpty else { return }
        let start = Date.now.timeIntervalSince1970

        await withTaskGroup(of: (String, GpxTrackLog?).self) { group in
            var limit = min(gpxURLs.count, GeoTagApp.maxConcurrentTasks)
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
        let duration = Date.now.timeIntervalSince1970 - start
        Self.logger.info("""
            \(gpxURLs.count, privacy: .public) tracks added in \
            \(duration, privacy: .public) seconds
            """)
    }
}
