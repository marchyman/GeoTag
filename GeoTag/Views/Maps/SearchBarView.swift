import SwiftUI
import UDF

struct SearchBarView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
    @Environment(\.colorScheme) var colorScheme

    var mapFocus: FocusState<MapWithSearchView.MapFocus?>.Binding
    @Binding var searchInfo: MapWithSearchView.SearchInfo

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
                    TextField(" Search location", text: $searchInfo.searchText)
                        .disableAutocorrection(true)
                        .focusEffectDisabled()
                        .focused(mapFocus, equals: .search)
                        .overlay(alignment: .trailing) {
                            if mapFocus.wrappedValue == .search {
                                Button {
                                    mapFocus.wrappedValue = nil
                                    searchInfo.searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.borderless)
                                .offset(x: -5)
                            }
                        }
                        .onExitCommand {
                            mapFocus.wrappedValue = nil
                            searchInfo.searchText = ""
                        }
                        .onSubmit {
                            mapFocus.wrappedValue = .searchList
                            searchInfo.picked.toggle()
                        }
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
            }
            .frame(height: 40)
    }
}

#Preview {
    @Previewable @State var searchInfo = MapWithSearchView.SearchInfo()
    @FocusState var mapFocus: MapWithSearchView.MapFocus?

    SearchBarView(mapFocus: $mapFocus, searchInfo: $searchInfo)
        .frame(maxWidth: 400)
        .padding()
        .environment(Store(initialState: GeoTagState(),
                           reduce: GeoTagReducer()))
}
