//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import MapAndSearchViews
import SplitVView
import SwiftUI

struct ImageMapView: View {
    @AppStorage(AppSettings.splitVImageMapKey) var percent: Double = 0.60
    @Environment(AppState.self) var state

    var body: some View {
        SplitVView(percent: $percent) {
            ImageView()
        } bottom: {
            MapAndSearchView(
                masData: state.masData,
                mainPin: state.tvm.mostSelected,
                allPins: state.tvm.selected
            ) { coords in
                if !state.tvm.selected.isEmpty {
                    state.undoManager.beginUndoGrouping()
                    for image in state.tvm.selected {
                        state.update(image, location: coords)
                    }
                    state.undoManager.endUndoGrouping()
                    state.undoManager.setActionName("modify location")
                }
            }
        }
    }
}

#Preview {
    ImageMapView()
        .environment(AppState())
}
