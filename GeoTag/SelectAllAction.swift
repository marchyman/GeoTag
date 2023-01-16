//
//  SelectAllAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/16/23.
//

import Foundation

extension ViewModel {

    func selectAllDisabled() -> Bool {
        let keyWindow = window?.isKeyWindow ?? false
        return !keyWindow || images.isEmpty
    }

    func selectAllAction() {
        selection = Set(images.map { $0.id })
    }
}
