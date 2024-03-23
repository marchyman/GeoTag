//
//  SearchBarView.swift
//  SMap
//
//  Created by Marco S Hyman on 3/11/24.
//

import SwiftUI

struct SearchBarView: View {
    @Environment(\.colorScheme) var colorScheme

    var mapFocus: FocusState<MapView.MapFocus?>.Binding
    var searchState: SearchState
    @State private var workingSearch: String = ""

    private var searchBackgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(searchBackgroundColor)
            .overlay {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.primary)
                    TextField(" Search location", text: $workingSearch )
                        .disableAutocorrection(true)
                        .focusEffectDisabled()
                        .focused(mapFocus, equals: .search)
                        .focusedValue(\.textfieldFocused, true)
                        .overlay(alignment: .trailing) {
                            if mapFocus.wrappedValue == .search {
                                Button {
                                    mapFocus.wrappedValue = .map
                                    workingSearch = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.borderless)
                                .offset(x: -5)
                            }
                        }
                        .onKeyPress(.escape) {
                            mapFocus.wrappedValue = .map
                            return .handled
                        }
                        .onSubmit {
                            searchState.searchText = workingSearch
                            workingSearch = ""
                            mapFocus.wrappedValue = .searchList
                        }
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
            }
            .frame(height: 40)
    }
}

#Preview {
    @FocusState var mapFocus: MapView.MapFocus?
    return SearchBarView(mapFocus: $mapFocus, searchState: SearchState())
        .frame(maxWidth: 400)
        .padding()
}
