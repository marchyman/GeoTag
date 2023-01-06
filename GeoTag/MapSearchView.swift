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

        func controlTextDidChange(_ obj: Notification) {
            if let searchField = obj.object as? NSSearchField {
                text = searchField.stringValue
            }
        }
    }

    func makeCoordinator() -> MapSearchView.Coordinator {
        return Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField.searchFieldWithMenu()
        searchField.delegate = context.coordinator
        return searchField
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
    }
}

struct MapSearchView_Previews: PreviewProvider {
    static var previews: some View {
        MapSearchView(text: .constant(""))
    }
}

// Can not update searchMenuTemplate in makeNSView.  Instead create a static
// function for NSSearchField that creates a view tht makeNSView can use.

extension NSSearchField {

    static func searchFieldWithMenu() -> NSSearchField {
        let searchesMenu: NSMenu = {
            let menu = NSMenu(title: "Recents")
            let i1 = menu.addItem(withTitle: "Recents Search", action: nil, keyEquivalent: "")
            i1.tag = Int(NSSearchField.recentsTitleMenuItemTag)
            let i2 = menu.addItem(withTitle: "Item", action: nil, keyEquivalent: "")
            i2.tag = Int(NSSearchField.recentsMenuItemTag)
            let i3 = menu.addItem(withTitle: "Clear", action: nil, keyEquivalent: "")
            i3.tag = Int(NSSearchField.clearRecentsMenuItemTag)
            let i4 = menu.addItem(withTitle: "No Recent Search", action: nil, keyEquivalent: "")
            i4.tag = Int(NSSearchField.noRecentsMenuItemTag)
            return menu
        }()

        let searchField = NSSearchField(frame: .zero)
        searchField.searchMenuTemplate = searchesMenu
        return searchField
    }
}
