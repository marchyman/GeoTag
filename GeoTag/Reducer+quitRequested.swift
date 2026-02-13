// Quit (or last window close) requested when there was a save
// in progress or there are unsaved changes.

extension GeoTagReducer {
    func quitRequested(_ state: inout GeoTagState) {
        if state.saveInProgress {
            state.addSheet(type: .savingUpdatesSheet)
        }

        if state.unsavedChanges {
            state.confirmationMessage = """
                If you quit GeoTag before saving changes the changes \
                will be lost.  Are you sure you want to quit?
                """
            state.confirmationEvent = .terminateRequest
            state.presentConfirmation.toggle()
        }
    }
}
