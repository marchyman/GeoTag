//
//  ImageView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/12/22.
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
                var tn = image.thumbnail
                if tn == nil {
                    tn = await image.makeThumbnail()
                }
                if image.thumbnail == nil {
                    image.thumbnail = tn
                }
                thumbnail = tn
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
