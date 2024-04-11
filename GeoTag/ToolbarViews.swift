//
//  ToolbarViews.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/10/24.
//

import PhotosUI
import SwiftUI

struct PhotoPickerView: View {
    @Environment(AppState.self) var state
    var photoLibrary = PhotoLibrary.shared

    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        Group {
            if photoLibrary.enabled {
                PhotosPicker(selection: $pickerItems,
                             matching: .images,
                             photoLibrary: .shared()) {
                    Label("Photo Library", systemImage: "photo")
                        .imageScale(.large)
                }
                             .keyboardShortcut("i", modifiers: [.shift, .command])
            } else {
                Button {
                    photoLibrary.requestAuth()
                } label: {
                    Label("Photo Library", systemImage: "photo")
                        .imageScale(.large)
                }
            }
        }
        .onChange(of: pickerItems) {
            Task.detached {
                await photoLibrary.addPhotos(from: pickerItems,
                                             to: state.tvm)
                pickerItems = []
            }
        }
    }
}

struct InspectorButtonView: View {
    @Environment(AppState.self) var state

    var body: some View {
        Button {
            state.inspectorPresented.toggle()
        } label: {
            Label("Toggle Inspector", systemImage: "info.circle")
        }
        .keyboardShortcut("i")
    }
}
