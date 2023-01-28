//
//  SelectAllAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/16/23.
//

import AppKit

extension AppViewModel {

    func selectAllDisabled() -> Bool {
        return images.isEmpty
    }

    func selectAllAction() {
        selection = Set(images.map { $0.id })
    }
}
