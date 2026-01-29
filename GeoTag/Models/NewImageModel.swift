// representation of an Image, its source, and metadata that may
// be edited

struct NewImageModel: Identifiable {
    let id: Int

    init() {
        id = NewImageModel.nextId()
    }
}
