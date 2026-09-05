import SwiftUI
import AVKit

struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer

    private static let pictureInPicture = PictureInPictureManager()

    static func togglePictureInPicture() {
        pictureInPicture.toggle()
    }

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .floating
        view.allowsPictureInPicturePlayback = true
        view.videoGravity = .resizeAspect
        Self.pictureInPicture.attach(player: player)
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
    }

}

/// Owns the system PiP session independently from the SwiftUI view lifecycle.
/// This keeps the floating video alive while the main window is resized or hidden.
private final class PictureInPictureManager {
    private var controller: AVPictureInPictureController?
    private var playerLayer: AVPlayerLayer?

    func attach(player: AVPlayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        if controller?.playerLayer.player !== player {
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspect
            playerLayer = layer
            controller = AVPictureInPictureController(playerLayer: layer)
        }
    }

    func toggle() {
        guard let controller, controller.isPictureInPicturePossible || controller.isPictureInPictureActive else { return }
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            controller.startPictureInPicture()
        }
    }
}
