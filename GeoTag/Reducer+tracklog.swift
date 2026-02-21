import GpxTrackLog
import Foundation

extension GeoTagReducer {
    func addTrackLog(_ state: inout GeoTagState, path: String, tracklog: GpxTrackLog?) {
        if let tracklog {
            state.gpxGoodFileNames.append(path)
            state.gpxTracks.append(tracklog)
            if !state.gpxTracks.isEmpty {
                state.gpxTracks.sort { $0.firstTimestamp < $1.firstTimestamp }
            }
        } else {
            state.gpxBadFileNames.append(path)
        }
    }
}
