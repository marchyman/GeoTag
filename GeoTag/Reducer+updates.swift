import Coords
import ImageData
import SwiftUI
import UDF

extension GeoTagReducer {
    func update(_ state: inout GeoTagState, coords: Coords) {
        // state.undoManager.beginUndoGrouping()
        for id in state.selection {
            update(&state.imageData[id], location: coords)
        }
        // state.undoManager.endUndoGrouping()
        // state.undoManager.setActionName("update location")
    }

    func update(_ image: inout ImageData, location: Coords) {
        print("update image \(image.name)")
    }
}
