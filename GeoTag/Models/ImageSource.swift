// GeoTag Images can come from a file on disk or an entry
// in the users Photos library.

// interesting note: both PhotosUI and SwiftUI must be imported
// or PhotosPickerItem isn't seen

import Foundation
import PhotosUI
import SwiftUI

enum ImageSource {
    case file(FileSource)
    case photos(PhotosSource)
}

struct FileSource {
    let url: URL
}

struct PhotosSource {
    let item: PhotosPickerItem
    let asset: PHAsset
}
