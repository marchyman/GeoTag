import PhotosUI
import SwiftUI
import UDF

struct PhotoPickerView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
    // var photoLibrary = PhotoLibrary.shared
    //
    // @State private var pickerItems: [PhotosPickerItem] = []
    //
    var body: some View {
        Button {
            //
        } label: {
            Label("Photo Library", systemImage: "photo")
                .imageScale(.large)
        }
        .keyboardShortcut("i", modifiers: [.shift, .command])
        // Group {
        //     if photoLibrary.enabled {
        //         PhotosPicker(
        //             selection: $pickerItems,
        //             matching: .images,
        //             photoLibrary: .shared()
        //         ) {
        //             Label("Photo Library", systemImage: "photo")
        //                 .imageScale(.large)
        //         }
        //         .keyboardShortcut("i", modifiers: [.shift, .command])
        //     } else {
        //         Button {
        //             photoLibrary.requestAuth {
        //                 Task { @MainActor in
        //                     if photoLibrary.enabled {
        //                         state.libraryEnabledMessage = true
        //                     } else {
        //                         state.libraryDisabledMessage = true
        //                     }
        //                 }
        //             }
        //         } label: {
        //             Label("Photo Library", systemImage: "photo")
        //                 .imageScale(.large)
        //         }
        //     }
        // }
        // .onChange(of: pickerItems) {
        //     let selectedItems = pickerItems
        //     pickerItems = []
        //     Task {
        //         await photoLibrary.addPhotos(from: selectedItems, to: state.tvm)
        //     }
        // }
        // .onAppear {
        //     AppState.logger.info("PhotoPickerView appeared")
        // }
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
