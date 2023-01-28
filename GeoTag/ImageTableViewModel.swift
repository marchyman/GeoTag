//
//  ImageTableViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/28/23.
//

import SwiftUI

final class ImageTableViewModel: ObservableObject {
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg

    public static let shared = ImageTableViewModel()

    let timestampMinWidth = 130.0
    let coordMinWidth = 120.0
}
