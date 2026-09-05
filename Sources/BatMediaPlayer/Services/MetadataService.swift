import Foundation
import AVFoundation

struct MediaMetadata {
    var title: String?
    var artist: String?
    var album: String?
    var artwork: Data?
    var duration: Double?
}

enum MetadataService {
    static func load(for url: URL) async -> MediaMetadata {
        let asset = AVURLAsset(url: url)
        var meta = MediaMetadata()

        if let common = try? await asset.load(.commonMetadata) {
            for item in common {
                switch item.commonKey {
                case .commonKeyTitle:
                    meta.title = try? await item.load(.stringValue)
                case .commonKeyArtist:
                    meta.artist = try? await item.load(.stringValue)
                case .commonKeyAlbumName:
                    meta.album = try? await item.load(.stringValue)
                case .commonKeyArtwork:
                    meta.artwork = try? await item.load(.dataValue)
                default:
                    break
                }
            }
        }

        if let duration = try? await asset.load(.duration) {
            let seconds = duration.seconds
            if seconds.isFinite, seconds > 0 { meta.duration = seconds }
        }

        return meta
    }
}
