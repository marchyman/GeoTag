//
//  ImageView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/12/22.
//

import SwiftUI

struct ImageView: View {
    @EnvironmentObject var vm: AppState

    var body: some View {
        Group {
            if let id = vm.mostSelected, let image = vm[id].thumbnail {
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
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView()
            .environmentObject(AppState())
    }
}
