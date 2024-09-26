# Searchable Map View in SwiftUI

This code was extracted from GeoTag and turned into a package to Help
in program organization and maybe speed up development time. The package
contains a Map View along with a search bar and search result views.
Pins on the map are represented as a `Locatable` type, a protocol that defines
an optional CLLocationCoordinate2D variable named location. The type is
also assumed to be `@Observable` to track location changes made to the pins.

Use the package something like this:

```swift
struct SomeView: View {
    @State private var state = ProgramState()
    @State private var masData = MapAndSearchData()

    var body: some View {
        MapAndSearchView(masData: masData,
                         mainPin: state.mainPin,
                         allPins: state.selectedPins) { coords in
            // process location updates here, something like:
            if !state.selectedPins.isEmpty {
                state.undoManager.beginUndoGrouping()
                for pin in state.selectedPins {
                    state.update(pin, location: coords)
                }
                state.undoManager.endUndoGrouping()
                state.undoManager.setActionName("modify location")
            }
        }
    }
}
```

mainPin:
    an optional of some type that conforms to the Locatable protocol.
    If a non-nil item is passed with a non-nil location a red pin will be
    placed on the map at the location.  mainPin is assumed exist in the
    array of allPins.

allPins:
    an array of types that conform to the Locatable protocol.  The array
    may be empty in which case mainPin would be nil. Items with a non-nil
    location may be shown on the map using an yellow pin.  This is controlled
    by the public property of MapAndSearchData named `showOtherPins`.

## Public items

- Locatable

- MapAndSearchData

  - MapAndSearchData.showOtherPins
    Enable/Disable view of other pins

  - MapAndSearchData.searchBarActive
    True when the search bar is active. May be used to enable system pasteboard
    processing vs app specific overrides.

  - MapAndSearchData.add(coords: CLLocationCoordinate2D)
    Add track logs to the map

  - MapAndSearchData.removeTracks()
    Remove all tracks from the map

  - MapAndSearchData.trackColor
    Track log color (stored in UserDefaults)

  - MapAndSearchData.trackWidth
    Track log line width (stored in UserDefaults)

- MapAndSearchView

## UserDefaults

The following are stored in user defaults. They can be accessed and set
as properties of `MapAndSearchData`.  The UserDefaults key is the name
of the property with an upper cased initial character.  Most are only
used/needed within the package.

- initialMapLatitude
- initialMapLongitude
- initialMapDistance
- savedMapStyle
- trackColor
- trackWidth
