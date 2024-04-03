//
//  SearchBarView.swift
//  SMap
//
//  Created by Marco S Hyman on 3/11/24.
//

import SwiftUI

struct SearchBarView: View {
    @Environment(\.colorScheme) var colorScheme

    var mapFocus: FocusState<MapWrapperView.MapFocus?>.Binding
    @Bindable var searchState: SearchState

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
                    TextField(" Search location", text: $searchState.searchText )
                        .disableAutocorrection(true)
                        .focusEffectDisabled()
                        .focused(mapFocus, equals: .search)
                        .focusedValue(\.textfieldFocused,
                                       searchState.searchText)
                        .overlay(alignment: .trailing) {
                            if mapFocus.wrappedValue == .search {
                                Button {
                                    mapFocus.wrappedValue = nil
                                    searchState.searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.borderless)
                                .offset(x: -5)
                            }
                        }
                        .onExitCommand {
                            mapFocus.wrappedValue = nil
                        }
                        .onSubmit {
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
    @FocusState var mapFocus: MapWrapperView.MapFocus?
    return SearchBarView(mapFocus: $mapFocus, searchState: SearchState())
        .frame(maxWidth: 400)
        .padding()
}
