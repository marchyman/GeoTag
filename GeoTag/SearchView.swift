//
//  SearchView.swift
//  SMap
//
//  Created by Marco S Hyman on 3/11/24.
//

import MapKit
import SwiftUI

struct SearchView: View {
    var mapFocus: FocusState<MapWrapperView.MapFocus?>.Binding

    var searchState: SearchState

    @State private var searchResponse: [SearchPlace] = []
    @State private var selection: SearchPlace?

    let leadingInset = 25.0

    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $selection) {
                Button {
                    searchState.searchText = ""
                    mapFocus.wrappedValue = nil
                } label: {
                    Text("Cancel")
                        .padding(.horizontal)
                }
                .padding(.vertical)

                Section {
                    ForEach(searchResponse, id: \.self) { item in
                        Text(item.name)
                            .font(.title2)
                            .bold()
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets.init(top: 0,
                                                   leading: leadingInset,
                                                   bottom: 0,
                                                   trailing: 0))
                } header: {
                    Text("Current search response:")
                        .font(.subheadline)
                }
                .listSectionSeparator(.hidden)

                Section {
                    if searchState.searchPlaces.isEmpty {
                        Text("None")
                            .foregroundStyle(.secondary)
                            .padding(.leading, leadingInset)
                    } else {
                        ForEach(searchState.searchPlaces, id: \.self) { item in
                            Text(item.name)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets.init(top: 0,
                                                       leading: leadingInset,
                                                       bottom: 0,
                                                       trailing: 0))
                        Button {
                            searchState.clearPlaces()
                        } label: {
                            Text("Clear list")
                        }
                        .padding(.vertical)
                        .padding(.leading, leadingInset)
                    }
                } header: {
                    Text("Previously selected locations:")
                        .font(.subheadline)
                }
                .listSectionSeparator(.hidden)
            }
            .padding()
        }
        .background(.gray.opacity(0.90))
        .cornerRadius(20)
        .scrollContentBackground(.hidden)
        .focused(mapFocus, equals: .searchList)
        .padding()
        .onChange(of: selection) {
            searchState.saveResult(selection)
            mapFocus.wrappedValue = nil
        }
        .onKeyPress(.escape) {
            searchState.searchText = ""
            mapFocus.wrappedValue = nil
            return .handled
        }
        .task(id: searchState.searchText) {
            if searchState.searchText.isEmpty {
                searchResponse = []
            } else {
                search(for: searchState.searchText)
//                mapFocus.wrappedValue = .searchList
            }
        }
    }

    private func search(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // search the entire world
        let center = LocationModel.shared.cameraPosition.camera?.centerCoordinate ??
            CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let span = MKCoordinateSpan(latitudeDelta: 90.0,
                                    longitudeDelta: 180.0)
        request.region = MKCoordinateRegion(center: center,
                                            span: span)
        Task {
            let searcher = MKLocalSearch(request: request)
            if let response = try? await searcher.start() {
                await MainActor.run {
                    searchResponse = response.mapItems.map {
                        SearchPlace(from: $0)
                    }
                }
            }
        }
    }
}

#Preview {
    @FocusState var mapFocus: MapWrapperView.MapFocus?
    return SearchView(mapFocus: $mapFocus,
                      searchState: SearchState())
}
