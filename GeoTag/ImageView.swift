//
//  ImageView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/12/22.
//

import SwiftUI

struct ImageView: View {
    @Environment(AppViewModel.self) var avm
    @State private var thumbnail: NSImage?

    var body: some View {
        Group {
            if let image = thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 96))
                    .opacity(0.18)
            }
        }
        .padding()
        .task(id: avm.mostSelected) {
            if let id = avm.mostSelected {
                if avm[id].thumbnail == nil {
                    avm[id].thumbnail = await avm[id].makeThumbnail()
                }
                thumbnail = avm[id].thumbnail
                return
            }
            thumbnail = nil
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView()
            .environment(AppViewModel())
    }
}
