//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

struct ImageView: View {
    @Environment(AppState.self) var state
    @State private var thumbnail: Image?

    var body: some View {
        Group {
            if let image = thumbnail {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 96))
                    .opacity(0.18)
            }
        }
        .padding()
        .task(id: state.tvm.mostSelected) {
            if let image = state.tvm.mostSelected {
                let interval = state.markStart("thumbnail")
                defer { state.markEnd("thumbnail", interval: interval) }
                if image.thumbnail == nil {
                    image.thumbnail = await image.makeThumbnail()
                }
                thumbnail = image.thumbnail
                return
            }
            thumbnail = nil
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView()
            .environment(AppState())
    }
}
