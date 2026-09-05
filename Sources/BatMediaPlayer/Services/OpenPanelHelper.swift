import AppKit
import UniformTypeIdentifiers

enum OpenPanelHelper {
    static let m3uType = UTType(filenameExtension: "m3u") ?? .plainText

    static func present(multiple: Bool) -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = multiple
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio, .movie]
        panel.title = String(localized: "Open Files...")
        if panel.runModal() == .OK {
            return panel.urls
        }
        return []
    }

    static func presentSavePlaylist() -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [m3uType]
        panel.nameFieldStringValue = "Playlist.m3u"
        panel.title = String(localized: "Save Playlist...")
        if panel.runModal() == .OK {
            var url = panel.url!
            if url.pathExtension.lowercased() != "m3u" {
                url = url.deletingPathExtension().appendingPathExtension("m3u")
            }
            return url
        }
        return nil
    }

    static func presentOpenPlaylist() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [m3uType]
        panel.title = String(localized: "Load Playlist...")
        if panel.runModal() == .OK {
            return panel.url
        }
        return nil
    }
}
