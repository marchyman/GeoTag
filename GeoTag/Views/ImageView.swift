import ImageData
import SwiftUI
import UDF

struct ImageView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
    @Environment(\.displayScale) var displayScale
    @State private var thumbnail: Image?

    var body: some View {
        Group {
            if let image = thumbnail {
                image.resizable().aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 96))
                    .opacity(0.18)
            }
        }
        .padding()
        .task(id: store.mostSelected) {
            if let id = store.mostSelected {
                if store[id].thumbnail == nil {
                    thumbnail = await store[id].makeThumbnail(scale: displayScale)
                    if let thumbnail {
                        store.send(.newThumbnail(thumbnail), undoable: false)
                    }
                } else {
                    thumbnail = store[id].thumbnail
                }
                return
            }
            thumbnail = nil
        }
    }
}

#Preview(traits: .store) {
    ImageView()
        .frame(width: 400, height: 300)
}

#Preview("image", traits: .select(11)    ) {
    ImageView()
        .frame(width: 400, height: 300)
}
