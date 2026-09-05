import Foundation

struct RecentItem: Codable, Identifiable, Hashable {
    var id: URL { url }
    let url: URL
    var title: String
    var lastPlayed: Date
}

enum RecentFilesService {
    private static var fileURL: URL {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BatMediaPlayer", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("recent.json")
    }

    static func load() -> [RecentItem] {
        guard let data = try? Data(contentsOf: fileURL),
              let items = try? JSONDecoder().decode([RecentItem].self, from: data) else {
            return []
        }
        return items
    }

    static func save(_ items: [RecentItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL)
    }

    @discardableResult
    static func add(_ url: URL, title: String) -> [RecentItem] {
        var items = load()
        items.removeAll { $0.url == url }
        items.insert(RecentItem(url: url, title: title, lastPlayed: Date()), at: 0)
        items = Array(items.prefix(30))
        save(items)
        return items
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
