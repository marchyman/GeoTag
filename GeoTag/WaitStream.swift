import Foundation

class WaitStream {
    var continuation: AsyncStream<Bool>.Continuation
    let stream: AsyncStream<Bool>

    init() {
        var hold: AsyncStream<Bool>.Continuation?
        stream = AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            hold = continuation
        }
        continuation = hold!
    }
}
