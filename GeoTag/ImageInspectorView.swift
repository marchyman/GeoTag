//
//  ImageInspectorView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/10/23.
//

import SwiftUI

// show an inspector to modify image metadata if not nil

struct ImageInspectorView: View {
    @Environment(AppState.self) var state

    var body: some View {
        if let image = state.tvm.mostSelected {
            ImageInspectorForm(image: image)
        } else {
            VStack {
                ContentUnavailableView {
                    Image(systemName: "magnifyingglass.circle")
                } description: {
                    Text("Please select an image")
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ImageInspectorView()
}
