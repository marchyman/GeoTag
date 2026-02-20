import SwiftUI
import UDF

struct ImageView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
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
                    thumbnail = await store[id].makeThumbnail()
                    if let thumbnail {
                        store.send(.newThumbnail(thumbnail)) {
                            store.discardUndo()
                        }
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

#Preview {
    ImageView()
        .environment(Store(initialState: GeoTagState(),
                           reduce: GeoTagReducer()))
}
