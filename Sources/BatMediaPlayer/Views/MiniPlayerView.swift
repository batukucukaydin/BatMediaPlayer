import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var vm: PlayerViewModel

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(vm.currentItem?.title ?? "—")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                if let artist = vm.currentItem?.artist, !artist.isEmpty {
                    Text(artist)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if vm.currentItem == nil {
                    Text("Nothing Playing")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            controlRow
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let item = vm.currentItem {
            if let image = ArtworkCache.image(for: item.artwork, url: item.url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient.brand
                    Image(systemName: item.isVideo ? "film.fill" : "music.note")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
        } else {
            if let logo = AppLogo.image {
                Image(nsImage: logo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient.brand
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 18) {
            Button { vm.previous() } label: {
                Image(systemName: "backward.fill")
            }
            Button { vm.togglePlayPause() } label: {
                ZStack {
                    Circle().fill(LinearGradient.brand).frame(width: 34, height: 34)
                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: vm.isPlaying ? 0 : 1)
                }
            }
            Button { vm.next() } label: {
                Image(systemName: "forward.fill")
            }
            Button { vm.showMainWindow() } label: {
                Image(systemName: "arrow.up.backward.and.arrow.down.forward")
            }
            .help("Open Full Player")
            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
