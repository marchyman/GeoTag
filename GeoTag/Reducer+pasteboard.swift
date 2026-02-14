import AppKit
import ImageData

extension GeoTagReducer {
    func cut(_ state: inout GeoTagState) {
        copy(&state)
        delete(&state)
    }

    func copy(_ state: inout GeoTagState) {
        if let id = state.mostSelected {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(state.imageData[id].stringRepresentation,
                         forType: .string)
        }
    }

    func paste(_ state: inout GeoTagState) {
        let pb = NSPasteboard.general
        if let pasteVal = pb.string(forType: .string),
           let locn = ImageData.decodeStringRep(value: pasteVal) {
            for id in state.selection {
                update(&state, id: id, location: locn.0, elevation: locn.1)
            }
        }
    }

    func delete(_ state: inout GeoTagState) {
        for id in state.selection
            where state.imageData[id].metadata.location != nil {
            update(&state, id: id, location: nil)
        }
    }

    func selectAll(_ state: inout GeoTagState) {
        state.selection = Set(state.imageData.map { $0.id })
    }
}
