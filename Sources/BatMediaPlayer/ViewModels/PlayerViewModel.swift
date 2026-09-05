import SwiftUI
import AVFoundation
import MediaPlayer
import Combine
import UniformTypeIdentifiers

enum RepeatMode: String, CaseIterable {
    case off, all, one
}

struct Chapter: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let time: Double
}

final class PlayerViewModel: ObservableObject {
    @Published var playlist: [MediaItem] = []
    @Published var currentIndex: Int?
    @Published var currentItem: MediaItem?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Float = 1.0
    @Published var rate: Float = 1.0
    @Published var repeatMode: RepeatMode = .off
    @Published var shuffleEnabled = false
    @Published var recentItems: [RecentItem] = []
    @Published var sleepRemainingSeconds: Int = 0

    @Published var queue: [MediaItem] = []
    @Published var loopStart: Double?
    @Published var loopEnd: Double?
    @Published var chapters: [Chapter] = []
    @Published var subtitleOptions: [AVMediaSelectionOption] = []
    @Published var audioOptions: [AVMediaSelectionOption] = []
    @Published var selectedSubtitleIndex: Int?
    @Published var selectedAudioIndex: Int?

    let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var timeControlObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var sleepTimer: Timer?
    private var subtitleGroup: AVMediaSelectionGroup?
    private var audioGroup: AVMediaSelectionGroup?

    var totalDuration: Double {
        playlist.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var upNextTitle: String? {
        guard let idx = currentIndex else { return nil }
        let n = idx + 1
        guard n < playlist.count else {
            return repeatMode == .all ? playlist.first?.title : nil
        }
        return playlist[n].title
    }

    var sleepRemainingLabel: String {
        guard sleepRemainingSeconds > 0 else { return "" }
        let m = sleepRemainingSeconds / 60
        let s = sleepRemainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var loopLabel: String {
        if loopStart != nil && loopEnd != nil { return String(localized: "Loop A-B") }
        if loopStart != nil { return String(localized: "Loop A set") }
        return String(localized: "Set Loop")
    }

    var loopActive: Bool {
        loopStart != nil && loopEnd != nil
    }

    init() {
        recentItems = RecentFilesService.load()
        configurePlayer()
        configureRemoteCommands()
    }

    // MARK: - Setup

    private func configurePlayer() {
        player.volume = volume

        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.isPlaying = player.timeControlStatus == .playing
            }
        }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            let seconds = time.seconds
            if seconds.isFinite { self.currentTime = seconds }
            if let d = self.player.currentItem?.duration.seconds, d.isFinite, d > 0 {
                self.duration = d
            }
            if let end = self.loopEnd, let start = self.loopStart, end > start, self.currentTime >= end {
                self.seek(to: start)
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.itemDidEnd()
        }
    }

    // MARK: - Playlist management

    func addFiles(_ urls: [URL], autoplay: Bool = true) {
        let start = playlist.count
        for url in urls where !url.hasDirectoryPath {
            guard !playlist.contains(where: { $0.url == url }) else { continue }
            let item = MediaItem(url: url)
            playlist.append(item)
            loadMetadata(for: item)
        }
        if autoplay && currentIndex == nil && start < playlist.count {
            playItem(at: start)
        }
    }

    func remove(at offsets: IndexSet) {
        let currentURL = currentIndex.map { playlist[$0].url }
        playlist.remove(atOffsets: offsets)
        if let url = currentURL {
            if let idx = playlist.firstIndex(where: { $0.url == url }) {
                currentIndex = idx
            } else if !playlist.isEmpty {
                let fallback = min(offsets.min() ?? 0, playlist.count - 1)
                playItem(at: fallback)
            } else {
                reset()
            }
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        let currentURL = currentIndex.map { playlist[$0].url }
        playlist.move(fromOffsets: source, toOffset: destination)
        if let url = currentURL {
            currentIndex = playlist.firstIndex(where: { $0.url == url })
        }
    }

    func clear() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        playlist.removeAll()
        queue.removeAll()
        clearLoop()
        reset()
    }

    func playRecent(_ item: RecentItem) {
        if let idx = playlist.firstIndex(where: { $0.url == item.url }) {
            playItem(at: idx)
        } else {
            addFiles([item.url], autoplay: true)
        }
    }

    private func reset() {
        currentIndex = nil
        currentItem = nil
        currentTime = 0
        duration = 0
        isPlaying = false
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func loadMetadata(for item: MediaItem) {
        Task {
            let meta = await MetadataService.load(for: item.url)
            await MainActor.run { self.apply(meta, to: item) }
        }
    }

    private func apply(_ meta: MediaMetadata, to item: MediaItem) {
        guard let idx = playlist.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = playlist[idx]
        if let title = meta.title, !title.isEmpty { updated.title = title }
        updated.artist = meta.artist
        updated.album = meta.album
        updated.artwork = meta.artwork
        if let d = meta.duration { updated.duration = d }
        playlist[idx] = updated
        if currentIndex == idx {
            currentItem = updated
            updateNowPlaying()
        }
    }

    // MARK: - Playback

    func playItem(at index: Int) {
        guard playlist.indices.contains(index) else { return }
        currentIndex = index
        currentItem = playlist[index]
        let item = AVPlayerItem(url: playlist[index].url)
        player.replaceCurrentItem(with: item)
        player.rate = rate
        recentItems = RecentFilesService.add(playlist[index].url, title: playlist[index].title)
        resetTracks()
        loadChapters(for: playlist[index].url)
        itemStatusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            if item.status == .readyToPlay {
                DispatchQueue.main.async { self?.loadMediaSelection(for: item) }
            }
        }
        updateNowPlaying()
    }

    func play() {
        player.rate = rate
        updateNowPlaying()
    }

    func pause() {
        player.pause()
        updateNowPlaying()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func stop() {
        player.pause()
        player.seek(to: .zero)
        currentTime = 0
        updateNowPlaying()
    }

    func next() {
        if let item = queue.first {
            queue.removeFirst()
            playQueueItem(item)
            return
        }
        guard let idx = currentIndex, let n = nextIndex(from: idx) else { return }
        playItem(at: n)
    }

    func previous() {
        guard let idx = currentIndex else { return }
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        if let p = previousIndex(from: idx) {
            playItem(at: p)
        } else {
            seek(to: 0)
        }
    }

    func seek(to time: Double) {
        let clamped = max(0, min(time, duration > 0 ? duration : time))
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600),
                    toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clamped
        updateNowPlaying()
    }

    func setVolume(_ value: Float) {
        volume = max(0, min(1, value))
        player.volume = volume
    }

    func setRate(_ value: Float) {
        rate = max(0.5, min(2, value))
        if isPlaying { player.rate = rate }
    }

    func toggleShuffle() {
        shuffleEnabled.toggle()
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    // MARK: - Sleep timer

    func setSleepTimer(minutes: Int) {
        cancelSleepTimer()
        sleepRemainingSeconds = minutes * 60
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                guard let self else { timer.invalidate(); return }
                if self.sleepRemainingSeconds > 0 {
                    self.sleepRemainingSeconds -= 1
                } else {
                    self.cancelSleepTimer()
                    self.pause()
                }
            }
        }
    }

    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepRemainingSeconds = 0
    }

    // MARK: - Playlist utilities

    func removeDuplicates() {
        var seen = Set<URL>()
        let currentURL = currentIndex.map { playlist[$0].url }
        playlist = playlist.filter { seen.insert($0.url).inserted }
        if let url = currentURL {
            currentIndex = playlist.firstIndex(where: { $0.url == url })
        }
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func savePlaylist(to url: URL) {
        PlaylistService.save(playlist, to: url)
    }

    func loadPlaylist(from url: URL) {
        addFiles(PlaylistService.load(from: url), autoplay: false)
    }

    func clearRecent() {
        recentItems.removeAll()
        RecentFilesService.save(recentItems)
    }

    func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.title != "Mini Player" {
            window.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: - Queue

    func playNext(_ item: MediaItem) {
        queue.removeAll { $0.id == item.id }
        queue.insert(item, at: 0)
    }

    func addToQueue(_ item: MediaItem) {
        queue.removeAll { $0.id == item.id }
        queue.append(item)
    }

    func removeFromQueue(at offsets: IndexSet) {
        queue.remove(atOffsets: offsets)
    }

    func clearQueue() {
        queue.removeAll()
    }

    private func playQueueItem(_ item: MediaItem) {
        if let idx = playlist.firstIndex(where: { $0.id == item.id }) {
            playItem(at: idx)
        }
    }

    // MARK: - A-B Loop

    func setLoopPoint() {
        if loopStart == nil {
            loopStart = currentTime
            loopEnd = nil
        } else if loopEnd == nil {
            let end = currentTime
            if end > (loopStart ?? 0) {
                loopEnd = end
            } else {
                loopStart = end
            }
        } else {
            clearLoop()
        }
    }

    func clearLoop() {
        loopStart = nil
        loopEnd = nil
    }

    func jump(to time: Double) {
        seek(to: time)
    }

    // MARK: - Chapters

    private func loadChapters(for url: URL) {
        chapters = []
        Task {
            let asset = AVURLAsset(url: url)
            var result: [Chapter] = []
            if let groups = try? await asset.loadChapterMetadataGroups(bestMatchingPreferredLanguages: ["en", "tr"]) {
                for group in groups {
                    let start = group.timeRange.start.seconds
                    var title = ""
                    for item in group.items {
                        if let t = try? await item.load(.stringValue), !t.isEmpty {
                            title = t
                            break
                        }
                    }
                    if title.isEmpty { title = String(localized: "Chapter") }
                    result.append(Chapter(title: title, time: start))
                }
            }
            await MainActor.run { self.chapters = result }
        }
    }

    // MARK: - Media selection (subtitles / audio)

    private func resetTracks() {
        subtitleOptions = []
        audioOptions = []
        subtitleGroup = nil
        audioGroup = nil
        selectedSubtitleIndex = nil
        selectedAudioIndex = nil
    }

    private func loadMediaSelection(for item: AVPlayerItem) {
        if let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            subtitleGroup = group
            subtitleOptions = group.options
        }
        if let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            audioGroup = group
            audioOptions = group.options
        }
    }

    func selectSubtitle(_ index: Int) {
        guard let group = subtitleGroup else { return }
        if index < 0 || !subtitleOptions.indices.contains(index) {
            player.currentItem?.select(nil, in: group)
            selectedSubtitleIndex = nil
            return
        }
        let option = subtitleOptions[index]
        if selectedSubtitleIndex == index {
            player.currentItem?.select(nil, in: group)
            selectedSubtitleIndex = nil
        } else {
            player.currentItem?.select(option, in: group)
            selectedSubtitleIndex = index
        }
    }

    func selectAudio(_ index: Int) {
        guard let group = audioGroup, audioOptions.indices.contains(index) else { return }
        let option = audioOptions[index]
        if selectedAudioIndex == index {
            player.currentItem?.select(nil, in: group)
            selectedAudioIndex = nil
        } else {
            player.currentItem?.select(option, in: group)
            selectedAudioIndex = index
        }
    }

    // MARK: - Screenshot

    func captureCurrentFrame() {
        guard let item = player.currentItem else { return }
        let generator = AVAssetImageGenerator(asset: item.asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let time = CMTime(seconds: currentTime, preferredTimescale: 600)
        generator.generateCGImageAsynchronously(for: time) { [weak self] cgImage, _, _ in
            guard let cgImage else { return }
            let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            DispatchQueue.main.async {
                self?.saveScreenshot(image)
            }
        }
    }

    private func saveScreenshot(_ image: NSImage) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Screenshot.png"
        panel.title = String(localized: "Save Screenshot")
        if panel.runModal() == .OK, let url = panel.url {
            guard let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let data = rep.representation(using: .png, properties: [:]) else { return }
            try? data.write(to: url)
        }
    }

    // MARK: - Index helpers

    private func nextIndex(from idx: Int) -> Int? {
        guard !playlist.isEmpty else { return nil }
        if shuffleEnabled {
            guard playlist.count > 1 else { return 0 }
            var r = idx
            while r == idx { r = Int.random(in: 0..<playlist.count) }
            return r
        }
        let n = idx + 1
        if n < playlist.count { return n }
        return repeatMode == .all ? 0 : nil
    }

    private func previousIndex(from idx: Int) -> Int? {
        guard !playlist.isEmpty else { return nil }
        let p = idx - 1
        if p >= 0 { return p }
        return repeatMode == .all ? playlist.count - 1 : nil
    }

    private func itemDidEnd() {
        switch repeatMode {
        case .one:
            player.seek(to: .zero)
            player.rate = rate
        case .all:
            next()
        case .off:
            if queue.isEmpty, let idx = currentIndex, nextIndex(from: idx) == nil {
                stop()
            } else {
                next()
            }
        }
    }

    // MARK: - Now Playing + Remote commands

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in self?.play(); return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in self?.togglePlayPause(); return .success }
        center.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        center.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let item = currentItem else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: item.title,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? rate : 0
        ]
        if let artist = item.artist { info[MPMediaItemPropertyArtist] = artist }
        if let album = item.album { info[MPMediaItemPropertyAlbumTitle] = album }
        if let data = item.artwork, let image = NSImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
