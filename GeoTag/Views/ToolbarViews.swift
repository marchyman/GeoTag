import PhotosUI
import SwiftUI
import UDF

struct PhotoPickerView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
    var photoLibrary = PhotoLibrary.shared

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var libraryEnabled = false
    @State private var libraryDisabled = false

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
                    photoLibrary.requestAuth {
                        Task { @MainActor in
                            if photoLibrary.enabled {
                                libraryEnabled.toggle()

                            } else {
                                libraryDisabled.toggle()
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
            if !pickerItems.isEmpty {
                let selectedItems = pickerItems
                pickerItems = []
                Task {
                    store.beginUndoGroup(description: "add from photos lib")
                    await photoLibrary.addPhotos(from: selectedItems,
                                                 store: store)
                    store.endUndoGroup()
                }
            }
        }
        .photoLibraryEnabledAlert(isPresented: $libraryEnabled)
        .photoLibraryDisabledAlert(isPresented: $libraryDisabled)
    }
}

struct InspectorButtonView: View {
    @Binding var presented: Bool

    var body: some View {
        Button {
            presented.toggle()
        } label: {
            Label("Toggle Inspector", systemImage: "info.circle")
        }
        .keyboardShortcut("i")
    }
}
