//
// Copyright 2022 Marco S Hyman
// https://www.snafu.org/
//

import MapAndSearchViews
import SwiftUI

struct MapView: View {
    @Environment(AppState.self) var state

    var body: some View {
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

#Preview {
    MapView()
        .environment(AppState())
}
