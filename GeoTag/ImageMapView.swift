//
//  ImageMapView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/21/22.
//

import MapAndSearchViews
import SwiftUI
import SplitVView

struct ImageMapView: View {
    @AppStorage(AppSettings.splitVImageMapKey) var percent: Double = 0.60
    @Environment(AppState.self) var state
    @State private var masData: MapAndSearchData

    var body: some View {
        SplitVView(percent: $percent) {
            ImageView()
        } bottom: {
            MapAndSearchView(masData: masData,
                             mainPin: state.tvm.mostSelected,
                             allPins: state.tvm.selection) { coords in
                if !state.tvm.selected.isEmpty {
                    state.undoManager.beginUndoGrouping()
                    for image in state.selected {
                        state.update(image, location: coords)
                    }
                    state.undoManager.endUndoGrouping()
                    state.undoManager.setActionName("modify location")
                }
            }
        }
    }
}

struct ImageMapView_Previews: PreviewProvider {
    static var previews: some View {
        ImageMapView()
            .environment(AppState())
    }
}
