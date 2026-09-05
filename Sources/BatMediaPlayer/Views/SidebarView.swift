import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var vm: PlayerViewModel
    @State private var searchText = ""

    private var filteredPlaylist: [MediaItem] {
        guard !searchText.isEmpty else { return vm.playlist }
        return vm.playlist.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.artist ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.album ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var summaryText: String {
        let count = vm.playlist.count
        let tracks = count == 1 ? String(localized: "track") : String(localized: "tracks")
        return "\(count) \(tracks) · \(formatTime(vm.totalDuration))"
    }

    var body: some View {
        VStack(spacing: 0) {
            sidebarHeader
            searchField

            List {
                if !vm.queue.isEmpty {
                    Section {
                        ForEach(vm.queue) { item in
                            queueRow(item)
                        }
                        .onDelete { offsets in
                            vm.removeFromQueue(at: offsets)
                        }
                    } header: {
                        HStack {
                            Text("Queue")
                            Spacer()
                            Button {
                                vm.clearQueue()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            .help("Clear Queue")
                        }
                    }
                }

                Section {
                    if filteredPlaylist.isEmpty {
                        emptyPlaylistHint
                    } else {
                        ForEach(filteredPlaylist) { item in
                            playlistRow(item)
                        }
                        .onMove { source, destination in
                            vm.move(from: source, to: destination)
                        }
                        .onDelete { offsets in
                            vm.remove(at: offsets)
                        }
                    }
                } header: {
                    Text("Playlist")
                }

                Section {
                    if vm.recentItems.isEmpty {
                        Text("No recent files")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(vm.recentItems) { item in
                            recentRow(item)
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent")
                        Spacer()
                        if !vm.recentItems.isEmpty {
                            Button {
                                vm.clearRecent()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            .help("Clear Recent")
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Divider()

            bottomBar
        }
    }

    // MARK: - Search

    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            if let logo = AppLogo.image {
                Image(nsImage: logo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            } else {
                Image(systemName: "waveform")
                    .foregroundStyle(LinearGradient.brand)
                    .frame(width: 30, height: 30)
                    .listeningSurface(cornerRadius: 9)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("BAT MEDIA")
                    .font(.appCaption)
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                Text("Listening room")
                    .font(.appBodyMedium)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.callout)
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.callout)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.surfaceElevated)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.outline, lineWidth: 1))
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .font(.appBody)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Text(summaryText)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()

            Button {
                let urls = OpenPanelHelper.present(multiple: true)
                vm.addFiles(urls, autoplay: false)
            } label: {
                Image(systemName: "plus")
            }
            .help("Add Files...")

            Menu {
                Button("Save Playlist...") {
                    if let url = OpenPanelHelper.presentSavePlaylist() {
                        vm.savePlaylist(to: url)
                    }
                }
                Button("Load Playlist...") {
                    if let url = OpenPanelHelper.presentOpenPlaylist() {
                        vm.loadPlaylist(from: url)
                    }
                }
                Divider()
                Button("Remove Duplicates") {
                    vm.removeDuplicates()
                }
                .disabled(vm.playlist.count < 2)
                Divider()
                Button("Clear Recent") {
                    vm.clearRecent()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .help("More")

            Button {
                vm.clear()
            } label: {
                Image(systemName: "trash")
            }
            .help("Clear Playlist")
            .disabled(vm.playlist.isEmpty)
        }
        .buttonStyle(.borderless)
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyPlaylistHint: some View {
        Text(searchText.isEmpty ? "Drag and drop music or video files here" : "No results")
            .font(.appBody)
            .foregroundColor(.secondary)
    }

    // MARK: - Rows

    private func queueRow(_ item: MediaItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "list.number")
                .foregroundColor(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .lineLimit(1)
                    .font(.appBodyMedium)
                if let artist = item.artist, !artist.isEmpty {
                    Text(artist)
                        .font(.appCaption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .contextMenu {
            Button("Remove", role: .destructive) {
                if let i = vm.queue.firstIndex(of: item) {
                    vm.removeFromQueue(at: IndexSet(integer: i))
                }
            }
        }
    }

    private func playlistRow(_ item: MediaItem) -> some View {
        let index = vm.playlist.firstIndex(of: item)
        let isCurrent = index == vm.currentIndex
        return HStack(spacing: 10) {
            thumbnail(item)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .lineLimit(1)
                    .fontWeight(isCurrent ? .semibold : .regular)
                if let artist = item.artist, !artist.isEmpty {
                    Text(artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isCurrent, vm.isPlaying {
                EqualizerView(isPlaying: true, barCount: 3, barWidth: 3, barSpacing: 2)
                    .frame(width: 14, height: 16)
            } else if let d = item.duration {
                Text(formatTime(d))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
        .listRowBackground(isCurrent ? Color.brand.opacity(0.18) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if let i = index { vm.playItem(at: i) }
        }
        .contextMenu {
            Button("Play") {
                if let i = index { vm.playItem(at: i) }
            }
            Button("Play Next") {
                vm.playNext(item)
            }
            Button("Add to Queue") {
                vm.addToQueue(item)
            }
            Button("Reveal in Finder") {
                vm.revealInFinder(item.url)
            }
            Divider()
            Button("Remove", role: .destructive) {
                if let i = index { vm.remove(at: IndexSet(integer: i)) }
            }
        }
    }

    @ViewBuilder
    private func thumbnail(_ item: MediaItem) -> some View {
        if let image = ArtworkCache.image(for: item.artwork, url: item.url) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LinearGradient.brand)
                Image(systemName: item.isVideo ? "film.fill" : "music.note")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .frame(width: 28, height: 28)
        }
    }

    private func recentRow(_ item: RecentItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .lineLimit(1)
                    .font(.appBodyMedium)
                Text(item.lastPlayed.formatted(date: .abbreviated, time: .shortened))
                    .font(.appCaption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            vm.playRecent(item)
        }
        .contextMenu {
            Button("Play") { vm.playRecent(item) }
            Button("Reveal in Finder") {
                vm.revealInFinder(item.url)
            }
            Button("Remove", role: .destructive) {
                vm.recentItems.removeAll { $0.url == item.url }
                RecentFilesService.save(vm.recentItems)
            }
        }
    }
}
