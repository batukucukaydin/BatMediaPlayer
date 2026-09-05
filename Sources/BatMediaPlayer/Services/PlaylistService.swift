import Foundation

enum PlaylistService {
    static func save(_ items: [MediaItem], to url: URL) {
        var lines = ["#EXTM3U"]
        for item in items {
            if let d = item.duration {
                lines.append("#EXTINF:\(Int(d)),\(item.title)")
            }
            lines.append(item.url.path)
        }
        try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    static func load(from url: URL) -> [URL] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        let base = url.deletingLastPathComponent()
        var result: [URL] = []
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            var path = URL(fileURLWithPath: trimmed)
            if !FileManager.default.fileExists(atPath: path.path) {
                let relative = base.appendingPathComponent(trimmed)
                if FileManager.default.fileExists(atPath: relative.path) {
                    path = relative
                }
            }
            result.append(path)
        }
        return result
    }
}
