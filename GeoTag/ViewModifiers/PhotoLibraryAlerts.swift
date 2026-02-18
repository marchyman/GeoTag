import SwiftUI

struct PhotoLibraryEnabledAlert: ViewModifier {
    @Binding var libraryEnabled: Bool

    func body(content: Content) -> some View {
        content
            .alert("Photo Library Access Allowed",
                   isPresented: $libraryEnabled) {
                // default action
            } message: {
                Text("""
                    Access to your Photos Library is now enabled. However \
                    you may need to quit and re-launch GeoTag before you \
                    can open your Photos Library.
                    """)
            }
    }
}

struct PhotoLibraryDisabledAlert: ViewModifier {
    @Binding var libraryDisabled: Bool

    func body(content: Content) -> some View {
        content
            .alert("Photo Library Access Denied",
                   isPresented: $libraryDisabled) {
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
    func photoLibraryEnabledAlert(isPresented: Binding<Bool>) -> some View {
        modifier(PhotoLibraryEnabledAlert(libraryEnabled: isPresented))
    }
    func photoLibraryDisabledAlert(isPresented: Binding<Bool>) -> some View {
        modifier(PhotoLibraryDisabledAlert(libraryDisabled: isPresented))
    }
}
