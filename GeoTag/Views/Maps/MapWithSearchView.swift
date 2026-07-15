import Coords
import CoreLocation
import SwiftUI
import UDF

public struct MapWithSearchView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    public enum MapFocus: Hashable {
        case map, search, searchList
    }

    // data shared between MapView, SearchBarView, and SearchView
    public struct SearchInfo {
        var picked: Bool = false
        var searchText = ""
        var selection: Place?
        var searchResponse: [Place] = []
        var recenterLocation: Coords?
    }

    @FocusState var mapFocus: MapFocus?
    @State var searchInfo = SearchInfo()

    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                MapView(mapFocus: $mapFocus, searchInfo: $searchInfo)

                SearchBarView(mapFocus: $mapFocus, searchInfo: $searchInfo)
                    .padding(30)
                    .frame(width: 400)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .bottomLeading)

                SearchView(mapFocus: $mapFocus, searchInfo: $searchInfo)
                    .frame(width: 400)
                    .frame(maxHeight: geometry.size.height > 70
                            ? geometry.size.height - 70 : 0,
                           alignment: .topLeading)
                    .opacity((mapFocus == .search || mapFocus == .searchList) ? 1.0 : 0)

            }
        }
        .onChange(of: mapFocus) {
            store.send(.textfieldFocusChanged(mapFocus == .search),
                       undoable: false)
            if store.mapSearchActive != (mapFocus == .search) {
                store.send(.findInMap(mapFocus == .search),
                           undoable: false)
            }
        }
        .onChange(of: store.mapSearchActive) {
            if store.mapSearchActive && mapFocus != .search {
                mapFocus = .search
            }
        }
    }
}

#Preview(traits: .store) {
    MapWithSearchView()
}
