//
//  ImageView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/12/22.
//

import SwiftUI

struct ImageView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if let selectedImage = appState.selectedImage {
                Image(nsImage: selectedImage)
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
