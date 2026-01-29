// representation of an Image, its source, and metadata that may
// be edited

struct NewImageModel: Identifiable {
    let id: Int
    let source: ImageSource

    init(from source: ImageSource ) {
        id = NewImageModel.nextId()
        self.source = source
    }
}
