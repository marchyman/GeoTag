//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

// show an inspector to modify image metadata if not nil

struct ImageInspectorView: View {
    @Environment(AppState.self) var state

    var body: some View {
        if let image = state.tvm.mostSelected {
            ImageInspectorForm(image: image)
        } else {
            ContentUnavailableView {
                Image(systemName: "magnifyingglass.circle")
            } description: {
                Text("Please select an image")
            }
        }
    }
}

#Preview {
    ImageInspectorView()
}
