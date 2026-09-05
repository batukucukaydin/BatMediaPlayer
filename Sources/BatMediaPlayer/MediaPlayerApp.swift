import SwiftUI
import AppKit

@main
struct BatMediaPlayerApp: App {
    @StateObject private var viewModel = PlayerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onOpenURL { url in
                    viewModel.addFiles([url])
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Files...") {
                    let urls = OpenPanelHelper.present(multiple: false)
                    viewModel.addFiles(urls, autoplay: true)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Add Files to Playlist...") {
                    let urls = OpenPanelHelper.present(multiple: true)
                    viewModel.addFiles(urls, autoplay: false)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }

            CommandMenu("Playback") {
                Button("Play/Pause") { viewModel.togglePlayPause() }
                    .keyboardShortcut(.space, modifiers: [])
                Button("Next") { viewModel.next() }
                    .keyboardShortcut(.rightArrow, modifiers: [.command])
                Button("Previous") { viewModel.previous() }
                    .keyboardShortcut(.leftArrow, modifiers: [.command])
                Button("Stop") { viewModel.stop() }
                    .keyboardShortcut(".", modifiers: [.command])
                Divider()
                Button("Increase Volume") { viewModel.setVolume(viewModel.volume + 0.1) }
                    .keyboardShortcut(.upArrow, modifiers: [.command])
                Button("Decrease Volume") { viewModel.setVolume(viewModel.volume - 0.1) }
                    .keyboardShortcut(.downArrow, modifiers: [.command])
                Divider()
                Button("Set Loop Point (A/B)") { viewModel.setLoopPoint() }
                    .keyboardShortcut("l", modifiers: [.command])
                Button("Screenshot") { viewModel.captureCurrentFrame() }
                    .keyboardShortcut("s", modifiers: [.command])
                Divider()
                Button("Toggle Picture in Picture") {
                    VideoPlayerView.togglePictureInPicture()
                }
                .disabled(viewModel.currentItem?.isVideo != true)
                .keyboardShortcut("p", modifiers: [.command, .option])
                Button("Toggle Mini Player") { MiniPlayerController.shared.toggle(viewModel) }
                    .keyboardShortcut("m", modifiers: [.command])
            }

            CommandMenu("Media") {
                Button("Add Audio or Video Files...") {
                    let urls = OpenPanelHelper.present(multiple: true)
                    viewModel.addFiles(urls, autoplay: false)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                Button("Clear Playlist", role: .destructive) {
                    viewModel.clear()
                }
                .disabled(viewModel.playlist.isEmpty)
            }
        }
    }
}

final class MiniPlayerController {
    static let shared = MiniPlayerController()
    private var window: NSWindow?
    private var viewModel: PlayerViewModel?

    func toggle(_ vm: PlayerViewModel) {
        if let window, window.isVisible {
            window.orderOut(nil)
            return
        }
        show(vm)
    }

    private func show(_ vm: PlayerViewModel) {
        viewModel = vm
        recreateWindow(with: vm)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func recreateWindow(with vm: PlayerViewModel) {
        if window != nil {
            window?.orderOut(nil)
            window = nil
        }
        let contentVC = NSHostingController(rootView: MiniPlayerView().environmentObject(vm))
        let window = NSWindow(contentViewController: contentVC)
        window.styleMask = [NSWindow.StyleMask.titled, NSWindow.StyleMask.closable, NSWindow.StyleMask.fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = NSWindow.TitleVisibility.hidden
        window.title = "Mini Player"
        window.isMovableByWindowBackground = true
        window.level = NSWindow.Level.floating
        window.setContentSize(NSSize(width: 440, height: 78))
        window.hasShadow = true
        window.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces
        window.isReleasedWhenClosed = false
        self.window = window
    }
}
