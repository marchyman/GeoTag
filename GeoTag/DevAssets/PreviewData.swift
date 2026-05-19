import GpxTrackLog
import ImageData
import Metadata
import SwiftUI
import UDF

extension GeoTagState {
    init(forPreview: Bool = false,
         withSelection: Set<Int>? = nil) {
        if forPreview {
            loadPreviewData()
            Task { @MainActor in
                @AppStorage(ImageTableView.hideInvalidImagesKey) var hideInvalidImages = false
                hideInvalidImages = false
            }
        }
        if let selection = withSelection {
            self.selection = selection
            self.mostSelected = selection.first
        }
    }

    mutating func loadPreviewData() {
        for url in previewURLs() {
            var item = ImageData(from: url)
            // exiftool can't read files from the bundle?
            // assume most files are updatable
            // Doesn't help with accessing xmp files
            if item.name != "image.foo" && item.name != "Screenshot.png" {
                item.original = Metadata(copying: item.metadata)
            }
            imageData.append(item)
        }
        linkPairedImages(true)
        imageData.sort(using: sortOrder)
        if let track = previewTrack() {
            gpxTracks.append(track)
        }
    }

    func previewURLs() -> [URL] {
        var urls: [URL] = []
        if let jpgs = Bundle.main.urls(forResourcesWithExtension: "JPG",
                                       subdirectory: nil) {
            urls.append(contentsOf: jpgs)
        }
        if let dngs = Bundle.main.urls(forResourcesWithExtension: "DNG",
                                       subdirectory: nil) {
            urls.append(contentsOf: dngs)
        }
        if let cr2s = Bundle.main.urls(forResourcesWithExtension: "CR2",
                                       subdirectory: nil) {
            urls.append(contentsOf: cr2s)
        }
        if let pngs = Bundle.main.urls(forResourcesWithExtension: "png",
                                       subdirectory: nil) {
            urls.append(contentsOf: pngs)
        }
        if let foos = Bundle.main.urls(forResourcesWithExtension: "foo",
                                       subdirectory: nil) {
            urls.append(contentsOf: foos)
        }

        return urls
    }

    func previewTrack() -> GpxTrackLog? {
        guard let trackURL = Bundle.main.url(forResource: "TestTrack",
                                             withExtension: "GPX") else {
            return nil
        }
        return try? GpxTrackLog(contentsOf: trackURL)
    }

    func previewAnotherTrack() -> GpxTrackLog? {
        guard let trackURL = Bundle.main.url(forResource: "AnotherTrack",
                                             withExtension: "GPX") else {
            return nil
        }
        return try? GpxTrackLog(contentsOf: trackURL)
    }
}

// pre loaded store
struct StoreTrait: PreviewModifier {
    func body(content: Content, context: Void) -> some View {
        content
            .environment(Store(initialState: GeoTagState(forPreview: true),
                               reduce: GeoTagReducer()))
    }
}

// pre loaded store with one or more items selected
struct SelectTrait: PreviewModifier {
    let selection: Set<Int>?

    func body(content: Content, context: Void) -> some View {
        content
            .environment(Store(initialState: GeoTagState(forPreview: true,
                                                         withSelection: selection),
                               reduce: GeoTagReducer()))
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static var store: Self = .modifier(StoreTrait())
    static func select(_ select: Int ...) -> Self {
        .modifier(SelectTrait(selection: Set(select)))
    }
}
