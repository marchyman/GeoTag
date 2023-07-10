//
//  ImageInspectorView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/10/23.
//

import SwiftUI

// show an inspector to modify image metadata if not nil

struct ImageInspectorView: View {
    var image: ImageModel?

    var body: some View {
        if let image {
            ImageInspectorForm(image: image)
        } else {
            ContentUnavailableView {
                Image(systemName: "magnifyingglass.circle")
            } description: {
                Text("Select an image to modify")
            }
        }
    }
}

#Preview {
    ImageInspectorView(image: nil)
}
