//
//  MapWrapperView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 3/24/24.
//

import SwiftUI

struct MapWrapperView: View {
    @State var searchState: SearchState = .init()

    enum MapFocus: Hashable {
        case map, search, searchList
    }

    @FocusState var mapFocus: MapFocus?

    var body: some View {
        // Using map overlay and/or safeAreaInset caused run time errors
        // instead of tracking those down I put the search bar and
        // search view in a ZStack with the map view
        ZStack {
            GeometryReader { geometry in
                MapView(mapFocus: $mapFocus,
                        searchState: $searchState,
                        mapHeight: geometry.size.height)

                SearchBarView(mapFocus: $mapFocus, searchState: searchState)
                    .padding(30)
                    .frame(width: 400)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .bottomLeading)

                if mapFocus == .search || mapFocus == .searchList {
                    SearchView(mapFocus: $mapFocus,
                               searchState: searchState)
                        .frame(width: 400)
                        .frame(maxWidth: .infinity,
                               maxHeight: geometry.size.height - 70,
                               alignment: .topLeading)
                }
            }
        }
    }
}

#Preview {
    MapWrapperView()
}
