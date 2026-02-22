extension GeoTagState {

    struct SheetInfo: Equatable {
        let sheetType: SheetType
        let sheetError: String?
        let sheetMessage: String?

        static func == (lhs: SheetInfo, rhs: SheetInfo) -> Bool {
            return lhs.sheetType == rhs.sheetType
                && lhs.sheetMessage == rhs.sheetMessage
        }
    }

    mutating func addSheet(type: SheetType, error: String? = nil, message: String? = nil) {
        if sheetType == nil {
            sheetType = type
            sheetError = error
            sheetMessage = message
        } else {
            // create a SheetInfo and add it to the stack of pending sheets
            sheetStack.append(
                SheetInfo(
                    sheetType: type,
                    sheetError: error,
                    sheetMessage: message))
        }
    }

    // Add a sheet of a given type only once.
    // [unused]

    // func hasSheet(type: SheetType) -> Bool {
    //     if sheetType == type {
    //         return true
    //     }
    //     return sheetStack.contains { $0.sheetType == type }
    // }

    // func addSheetOnce(type: SheetType, error: NSError? = nil, message: String? = nil) {
    //     if !hasSheet(type: type) {
    //         addSheet(type: type, error: error, message: message)
    //     }
    // }
}
