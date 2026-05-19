import SwiftUI

// stubs for test/development related items that live in DevAssets but are
// still required for a release build to compile

#if DEBUG
// nothing needed
#else

struct StoreTrait: PreviewModifier {
    func body(content: Content, context: Void) -> some View {
        content
    }
}

struct SelectTrait: PreviewModifier {
    let selection: Set<Int>?

    func body(content: Content, context: Void) -> some View {
        content
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static var store: Self = .modifier(StoreTrait())
    static func select(_ select: Int ...) -> Self {
        .modifier(SelectTrait(selection: Set(select)))
    }
}

#endif
