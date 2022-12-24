//
//  SizeReader.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/20/22.
//

import SwiftUI

extension View {
    func sizeReader(size: @escaping (CGSize) -> Void) -> some View {
        return self
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizeReaderPreferenceKey.self,
                                    value: geometry.size)
                        .onPreferenceChange(SizeReaderPreferenceKey.self) {
                            newValue in
                            size(newValue)
                        }
                }
                .hidden()
            )
    }

}

struct SizeReaderPreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
