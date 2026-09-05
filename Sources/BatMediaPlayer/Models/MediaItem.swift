import Foundation
import AppKit
import ImageIO

struct MediaItem: Identifiable, Hashable {
    var id: URL { url }
    let url: URL
    var title: String
    var artist: String?
    var album: String?
    var duration: Double?
    var artwork: Data?

    init(url: URL) {
        self.url = url
        self.title = url.deletingPathExtension().lastPathComponent
    }

    var isVideo: Bool {
        let ext = url.pathExtension.lowercased()
        return ["mp4", "mov", "m4v", "mpv", "mpeg", "mpg"].contains(ext)
    }
}

enum ArtworkCache {
    private static var cache: [URL: NSImage] = [:]
    private static let lock = NSLock()

    static func image(for data: Data?, url: URL) -> NSImage? {
        guard let data else { return nil }
        lock.lock()
        if let cached = cache[url] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        // Album art can be several thousand pixels wide. Decode a bounded
        // thumbnail so a metadata update does not stall the main UI thread or
        // allocate a full-size bitmap for a small card/list row.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 720,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        lock.lock()
        cache[url] = image
        lock.unlock()
        return image
    }
}
