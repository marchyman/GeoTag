//
//  ImageView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/12/22.
//

import SwiftUI

struct ImageView: View {
    @EnvironmentObject var vm: AppViewModel
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
        .onChange(of: vm.mostSelected) { id in
            Task {
                if let id {
                    vm[id].makeThumbnail()
                    thumbnail = vm[id].thumbnail
                } else {
                    thumbnail = nil
                }
            }
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView()
            .environmentObject(AppViewModel())
    }
}
