//
//  MapSearchView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/19/22.
//

import SwiftUI

/// Map search view contains a search field. make NSSearchField available in a SwiftUI wrapper

struct MapSearchView: NSViewRepresentable {
    @Binding var text: String

    class Coordinator: NSObject, NSSearchFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            if let searchField = obj.object as? NSSearchField {
                text = searchField.stringValue
            }
        }
    }

    func makeCoordinator() -> MapSearchView.Coordinator {
        return Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField(frame: .zero)
        searchField.delegate = context.coordinator
        searchField.searchMenuTemplate = makeSearchesMenu()
        return searchField
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
    }

    func makeSearchesMenu() -> NSMenu {
        let searchesMenu: NSMenu = NSMenu(title: "Recents")

        let i1 = searchesMenu.addItem(withTitle: "Recents Search",
                                      action: nil, keyEquivalent: "")
        i1.tag = Int(NSSearchField.recentsTitleMenuItemTag)

        let i2 = searchesMenu.addItem(withTitle: "Item",
                                      action: nil, keyEquivalent: "")
        i2.tag = Int(NSSearchField.recentsMenuItemTag)

        let i3 = searchesMenu.addItem(withTitle: "Clear",
                                      action: nil, keyEquivalent: "")
        i3.tag = Int(NSSearchField.clearRecentsMenuItemTag)

        let i4 = searchesMenu.addItem(withTitle: "No Recent Search",
                                      action: nil, keyEquivalent: "")
        i4.tag = Int(NSSearchField.noRecentsMenuItemTag)

        return searchesMenu
    }
}

struct MapSearchView_Previews: PreviewProvider {
    static var previews: some View {
        MapSearchView(text: .constant(""))
    }
}
