import SwiftUI

struct SearchBarView: View {
    @Environment(\.colorScheme) var colorScheme

    var mapFocus: FocusState<MapAndSearchView.MapFocus?>.Binding
    @Bindable var masData: MapAndSearchData

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
                    TextField(" Search location", text: $masData.searchText )
                        .disableAutocorrection(true)
                        .focusEffectDisabled()
                        .focused(mapFocus, equals: .search)
                        .overlay(alignment: .trailing) {
                            if mapFocus.wrappedValue == .search {
                                Button {
                                    mapFocus.wrappedValue = nil
                                    masData.searchText = ""
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
                            masData.pickFirst.toggle()
                        }
                        .onChange(of: mapFocus.wrappedValue) {
                            masData.searchBarActive = mapFocus.wrappedValue == .search
                        }
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
            }
            .frame(height: 40)
    }
}

#Preview {
    @FocusState var mapFocus: MapAndSearchView.MapFocus?
    return SearchBarView(mapFocus: $mapFocus, masData: MapAndSearchData())
        .frame(maxWidth: 400)
        .padding()
}
