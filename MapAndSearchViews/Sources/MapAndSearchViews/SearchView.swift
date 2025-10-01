//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import MapKit
import SwiftUI

struct SearchView: View {
    var mapFocus: FocusState<MapAndSearchView.MapFocus?>.Binding
    var masData: MapAndSearchData

    @State private var searchResponse: [SearchPlace] = []
    @State private var selection: SearchPlace?

    let leadingInset = 25.0

    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $selection) {
                Button {
                    masData.searchText = ""
                    mapFocus.wrappedValue = nil
                } label: {
                    Text("Cancel")
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .listRowSeparator(.hidden)

                Section {
                    ForEach(searchResponse, id: \.self) { item in
                        Text(item.name)
                            .font(.title2)
                            .bold()
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets.init(
                            top: 0,
                            leading: leadingInset,
                            bottom: 0,
                            trailing: 0))
                } header: {
                    Text("Current search response:")
                        .font(.subheadline)
                }
                .listSectionSeparator(.hidden)

                Section {
                    ForEach(masData.searchPlaces, id: \.self) { item in
                        Text(item.name)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets.init(
                            top: 0,
                            leading: leadingInset,
                            bottom: 0,
                            trailing: 0))
                    Button {
                        masData.clearPlaces()
                    } label: {
                        Text("Clear list")
                    }
                    .padding(.vertical)
                    .padding(.leading, leadingInset)
                } header: {
                    Text("Previously selected locations:")
                        .font(.subheadline)
                }
                .listSectionSeparator(.hidden)
                .opacity(masData.searchPlaces.isEmpty ? 0 : 1)
            }
            .padding()
        }
        .background(.gray.opacity(0.90))
        .cornerRadius(20)
        .scrollContentBackground(.hidden)
        .focused(mapFocus, equals: .searchList)
        .padding()
        .onChange(of: selection) {
            masData.saveResult(selection)
            mapFocus.wrappedValue = nil
            selection = nil
        }
        .onChange(of: masData.pickFirst) {
            if !searchResponse.isEmpty {
                masData.saveResult(searchResponse[0])
                mapFocus.wrappedValue = nil
            }
        }
        .onKeyPress(.escape) {
            masData.searchText = ""
            mapFocus.wrappedValue = nil
            return .handled
        }
        .task(id: masData.searchText) {
            // debounce search input
            do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
            if masData.searchText.isEmpty {
                searchResponse = []
            } else if mapFocus.wrappedValue != nil {
                let currentSearch = masData.searchText
                await search(for: currentSearch)
            }
        }
    }

    nonisolated private func search(for query: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let searcher = MKLocalSearch(request: request)
        if let response = try? await searcher.start() {
            let places = response.mapItems.map {
                SearchPlace(from: $0)
            }
            await MainActor.run {
                searchResponse = places
            }
        }
    }
}

#Preview {
    @FocusState var mapFocus: MapAndSearchView.MapFocus?
    return SearchView(
        mapFocus: $mapFocus,
        masData: MapAndSearchData())
}
