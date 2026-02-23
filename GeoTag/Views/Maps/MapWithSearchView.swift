import CoreLocation
import SwiftUI
import UDF

public struct MapWithSearchView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    enum MapFocus: Hashable {
        case map, search, searchList
    }

    @FocusState var mapFocus: MapFocus?

    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                MapView()

                SearchBarView(mapFocus: $mapFocus)
                    .padding(30)
                    .frame(width: 400)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .bottomLeading)

                SearchView(mapFocus: $mapFocus)
                    .frame(width: 400)
                    .frame(maxHeight: geometry.size.height > 70
                            ? geometry.size.height - 70 : 0,
                           alignment: .topLeading)
                    .opacity((mapFocus == .search || mapFocus == .searchList) ? 1.0 : 0)

            }
        }
        .onChange(of: store.mapSearchActive) {
            if store.mapSearchActive && mapFocus != .search {
                mapFocus = .search
            }
        }
    }
}

// #Preview {
//     struct Pins: Locatable {
//         var location: CLLocationCoordinate2D?
//     }
//     @Previewable @State var mainPin: Pins?
//     @Previewable @State var allPins: [Pins] = []
//     return MapAndSearchView(
//         masData: MapAndSearchData(),
//         mainPin: mainPin,
//         allPins: allPins
//     ) { location in
//         print("location changed \(location)")
//     }
// }
