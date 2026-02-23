import MapKit
import SwiftUI
import UDF

struct SearchView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    var mapFocus: FocusState<MapWithSearchView.MapFocus?>.Binding
    @Binding var searchInfo: MapWithSearchView.SearchInfo

    let leadingInset = 25.0

    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $searchInfo.selection) {
                Button {
                    searchInfo.searchText = ""
                    mapFocus.wrappedValue = nil
                } label: {
                    Text("Cancel")
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .listRowSeparator(.hidden)

                Section {
                    ForEach(searchInfo.searchResponse, id: \.self) { item in
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
                    ForEach(store.places, id: \.self) { item in
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
                        store.send(.clearPlaces)
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
                .opacity(store.places.isEmpty ? 0 : 1)
            }
            .padding()
        }
        .background(.gray.opacity(0.90))
        .cornerRadius(20)
        .scrollContentBackground(.hidden)
        .focused(mapFocus, equals: .searchList)
        .padding()
        .onChange(of: searchInfo.picked) {
            if let place = searchInfo.searchResponse.first {
                searchInfo.selection = place
            }
            mapFocus.wrappedValue = nil
            searchInfo.searchText = ""
        }
        .onChange(of: searchInfo.selection) {
            if let place = searchInfo.selection {
                store.send(.placeSelection(place))
                locationChanged(location: place.coordinate)
            }
            mapFocus.wrappedValue = nil
        }
        .onKeyPress(.escape) {
            searchInfo.searchText = ""
            mapFocus.wrappedValue = nil
            return .handled
        }
        .task(id: searchInfo.searchText) {
            // debounce search input
            do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
            if searchInfo.searchText.isEmpty {
                searchInfo.searchResponse = []
            } else if mapFocus.wrappedValue != nil {
                let currentSearch = searchInfo.searchText
                await search(for: currentSearch)
            }
        }
    }

    private func locationChanged(location: Coordinate) {
        if let id = store.mostSelected {
            store.send(.locationChanged(location.coord2D),
                       description: "search selection") {
                // remember the current selection
                let selected = store.selection
                Task {
                    let address =
                    await ReverseLocationFinder.reverseGeocode(store: store,
                                                               id: id)
                    if let address {
                        store.send(.addressChanged(selected, address),
                                   undoable: false)
                    }
                }
            }
        } else {
            searchInfo.recenterLocation = location.coord2D
        }
    }

    nonisolated private func search(for query: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.addressFilter = .includingAll
        let searcher = MKLocalSearch(request: request)
        if let response = try? await searcher.start() {
            let places = response.mapItems.map {
                Place(from: $0)
            }
            await MainActor.run {
                searchInfo.searchResponse = places
            }
        }
    }
}

// #Preview {
//     @Previewable @FocusState var mapFocus: MapWithSearchView.MapFocus?
//     SearchView(mapFocus: $mapFocus)
//         .environment(Store(initialState: GeoTagState(), reduce: GeoTagReducer()))
// }
