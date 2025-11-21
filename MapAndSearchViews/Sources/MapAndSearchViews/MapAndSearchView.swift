//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import CoreLocation
import SwiftUI

public struct MapAndSearchView: View {
    let masData: MapAndSearchData
    let mainPin: Locatable?
    let allPins: [Locatable]
    let updatePins: (CLLocationCoordinate2D) -> Void

    public init(
        masData: MapAndSearchData,
        mainPin: Locatable?,
        allPins: [Locatable],
        updatePins: @escaping (CLLocationCoordinate2D) -> Void
    ) {
        self.masData = masData
        self.mainPin = mainPin
        self.allPins = allPins
        self.updatePins = updatePins
    }

    enum MapFocus: Hashable {
        case map, search, searchList
    }

    @FocusState var mapFocus: MapFocus?

    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                MapView(
                    masData: masData,
                    mapFocus: $mapFocus,
                    mainPin: mainPin,
                    allPins: allPins,
                    updatePins: updatePins)

                SearchBarView(mapFocus: $mapFocus, masData: masData)
                    .padding(30)
                    .frame(width: 400)
                    .frame(
                        maxWidth: .infinity, maxHeight: .infinity,
                        alignment: .bottomLeading)

                SearchView(mapFocus: $mapFocus, masData: masData)
                    .frame(width: 400)
                    .frame(
                        maxHeight: geometry.size.height > 70
                            ? geometry.size.height - 70 : 0,
                        alignment: .topLeading
                    )
                    .opacity((mapFocus == .search || mapFocus == .searchList) ? 1.0 : 0)

                // show map center coords -- only used by XCUITesting
                Text(masData.centerLocation)
                    .padding()
                    .background(.thickMaterial)
                    .frame(
                        maxWidth: .infinity, maxHeight: .infinity,
                        alignment: .topTrailing
                    )
                    .opacity(masData.showLocation ? 1.0 : 0)
            }
        }
        .onChange(of: masData.searchBarActive) {
            if masData.searchBarActive && mapFocus != .search {
                mapFocus = .search
            }
        }
    }
}

#Preview {
    struct Pins: Locatable {
        var location: CLLocationCoordinate2D?
    }
    @Previewable @State var mainPin: Pins?
    @Previewable @State var allPins: [Pins] = []
    return MapAndSearchView(
        masData: MapAndSearchData(),
        mainPin: mainPin,
        allPins: allPins
    ) { location in
        print("location changed \(location)")
    }
}
