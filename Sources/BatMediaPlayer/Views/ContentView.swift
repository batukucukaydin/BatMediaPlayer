import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var vm: PlayerViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        }         detail: {
            VStack(spacing: 0) {
                ZStack {
                    if let item = vm.currentItem, item.isVideo {
                        VideoPlayerView(player: vm.player)
                    } else {
                        NowPlayingView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(vm.currentItem?.isVideo == true ? Color.black : Color.clear)

                Divider()
                PlayerControlsView()
            }
            .navigationTitle(vm.currentItem?.title ?? "BatMediaPlayer")
            .navigationSubtitle(vm.currentItem?.artist ?? "")
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Color.ink)
        .tint(.brand)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    let urls = OpenPanelHelper.present(multiple: true)
                    vm.addFiles(urls, autoplay: false)
                } label: {
                    Label("Add media", systemImage: "plus")
                }
                .help("Add audio or video files")

                Menu {
                    Button(vm.isPlaying ? "Pause" : "Play") { vm.togglePlayPause() }
                    Button("Previous") { vm.previous() }
                    Button("Next") { vm.next() }
                    Divider()
                    Button("Stop") { vm.stop() }
                } label: {
                    Label("Playback", systemImage: vm.isPlaying ? "pause.fill" : "play.fill")
                }

                Menu {
                    Button("Toggle Mini Player") { MiniPlayerController.shared.toggle(vm) }
                    Button("Picture in Picture") { VideoPlayerView.togglePictureInPicture() }
                        .disabled(vm.currentItem?.isVideo != true)
                    Button("Screenshot") { vm.captureCurrentFrame() }
                    Divider()
                    Button("Clear Playlist", role: .destructive) { vm.clear() }
                } label: {
                    Label("Tools", systemImage: "slider.horizontal.3")
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        let group = DispatchGroup()
        var urls: [URL] = []
        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else { continue }
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                } else if let url = item as? URL {
                    urls.append(url)
                } else if let str = item as? String, let url = URL(string: str) {
                    urls.append(url)
                }
            }
        }
        group.notify(queue: .main) {
            vm.addFiles(urls)
        }
        return true
    }
}
