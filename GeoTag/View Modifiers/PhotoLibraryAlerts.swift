//
// Copyright 2025 Marco S Hyman
// https://www.snafu.org/
//

import SwiftUI

struct PhotoLibraryEnabledAlert: ViewModifier {
    @Environment(AppState.self) var state
    func body(content: Content) -> some View {
        @Bindable var state = state
        content
            .alert("Photo Library Access Allowed",
                   isPresented: $state.libraryEnabledMessage) {
                // default action
            } message: {
                Text("""
                    Access to your Photos Library is now enabled. However \
                    you will need to quit and re-launch GeoTag before you \
                    can open your Photos Library.
                    """)
            }

    }
}

struct PhotoLibraryDisabledAlert: ViewModifier {
    @Environment(AppState.self) var state
    func body(content: Content) -> some View {
        @Bindable var state = state
        content
            .alert("Photo Library Access Denied",
                   isPresented: $state.libraryDisabledMessage) {
                // default action
            } message: {
                Text("""
                    Access to your Photos Library was denied. If you gave \
                    access to the program quit and re-launch GeoTag to \
                    make sure it is using the current state. If that does \
                    not resolve the issue open the Privacy and Security \
                    tab of System Settings and select Photos. Make sure \
                    GeoTag has full access.
                    """)
            }

    }
}
extension View {
    func photoLibraryEnabledAlert() -> some View {
        modifier(PhotoLibraryEnabledAlert())
    }
    func photoLibraryDisabledAlert() -> some View {
        modifier(PhotoLibraryDisabledAlert())
    }
}
