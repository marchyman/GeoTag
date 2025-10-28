//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import PhotosUI
import SwiftUI

struct PhotoPickerView: View {
    @Environment(AppState.self) var state
    var photoLibrary = PhotoLibrary.shared

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var enabled = false

    var body: some View {
        Group {
            if photoLibrary.enabled {
                PhotosPicker(
                    selection: $pickerItems,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Photo Library", systemImage: "photo")
                        .imageScale(.large)
                }
                .keyboardShortcut("i", modifiers: [.shift, .command])
            } else {
                Button {
                    photoLibrary.requestAuth {
                        Task { @MainActor in
                            if photoLibrary.enabled {
                                state.libraryEnabledMessage = true
                            } else {
                                state.libraryDisabledMessage = true
                            }
                        }
                    }
                } label: {
                    Label("Photo Library", systemImage: "photo")
                        .imageScale(.large)
                }
            }
        }
        .onChange(of: pickerItems) {
            let selectedItems = pickerItems
            pickerItems = []
            Task {
                await photoLibrary.addPhotos(from: selectedItems, to: state.tvm)
            }
        }
        .onChange(of: photoLibrary.enabled) {
            enabled = photoLibrary.enabled
        }
        .onAppear {
            enabled = photoLibrary.enabled
            AppState.logger.info("PhotoPickerView appeared")
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
