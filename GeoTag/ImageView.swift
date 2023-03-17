//
//  ImageView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/12/22.
//

import SwiftUI

struct ImageView: View {
    @EnvironmentObject var avm: AppViewModel
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
        .onChange(of: avm.mostSelected) { id in
            thumbnail = id == nil ? nil : avm[id].thumbnail
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView()
            .environmentObject(AppViewModel())
    }
}
