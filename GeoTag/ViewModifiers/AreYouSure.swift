import SwiftUI
import UDF

// modifier designed to add a confirmation dialog to any view that uses it.

struct AreYouSure: ViewModifier {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
    @State private var presentConfirmation = false

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Are you sure?",
            isPresented: $presentConfirmation)
        {
            Button("I'm sure", role: .destructive) {
                if let event = store.confirmationEvent {
                    store.send(event)
                }
            }
            .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) {}
                .keyboardShortcut(.cancelAction)
        } message: {
            let message = store.confirmationMessage ?? ""
            Text(message)
        }
        .onChange(of: store.presentConfirmation) {
            presentConfirmation.toggle()
        }
    }
}

extension View {
    func areYouSure() -> some View {
        modifier(AreYouSure())
    }
}
