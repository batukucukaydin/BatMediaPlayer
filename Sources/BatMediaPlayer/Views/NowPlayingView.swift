import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var vm: PlayerViewModel

    var body: some View {
        Group {
            if let item = vm.currentItem {
                GeometryReader { proxy in
                    ZStack {
                        background
                        VStack(spacing: 16) {
                            Spacer(minLength: 0)
                            artworkCard(for: item, size: artworkSize(in: proxy.size))
                            infoBlock(for: item)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brand.opacity(0.20), Color.brandPink.opacity(0.08), Color.ink],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .fill(LinearGradient.brand)
                .opacity(0.16)
                .frame(width: 460, height: 460)
                .blur(radius: 60)
                .offset(y: -160)
        }
        .ignoresSafeArea()
    }

    // MARK: - Artwork

    private func artworkSize(in size: CGSize) -> CGFloat {
        // Keep the transport controls visible even in a short window.
        let heightBudget = max(180, (size.height - 150) * 0.62)
        return min(360, max(180, min(size.width - 48, heightBudget)))
    }

    private func artworkCard(for item: MediaItem, size: CGFloat) -> some View {
        VStack(spacing: 0) {
            artworkImage(item)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            artworkImage(item)
                .frame(width: size, height: min(80, size * 0.28))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .scaleEffect(x: 1, y: -1)
                .mask(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: 6)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                .scaleEffect(x: 1, y: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 30, y: 18)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func artworkImage(_ item: MediaItem) -> some View {
        if let image = ArtworkCache.image(for: item.artwork, url: item.url) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                LinearGradient.brand
                if let logo = AppLogo.image {
                    Image(nsImage: logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 170, height: 170)
                } else {
                    Image(systemName: item.isVideo ? "film.fill" : "music.note")
                        .font(.system(size: 90, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }

    // MARK: - Info

    private func infoBlock(for item: MediaItem) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                if vm.isPlaying {
                    EqualizerView(isPlaying: true, barCount: 3, barWidth: 4, barSpacing: 3)
                        .frame(width: 18, height: 20)
                }
                Text(item.title)
                    .font(.appTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            if let artist = item.artist, !artist.isEmpty {
                Text(artist)
                    .font(.appBodyMedium)
                    .foregroundColor(.secondary)
            }
            if let album = item.album, !album.isEmpty {
                Text(album)
                    .font(.appCaption)
                    .tracking(0.4)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 18) {
            logoView(size: 120, cornerRadius: 26)
            Text("Nothing Playing")
                .font(.appTitle)
                .foregroundColor(.secondary)
            Text("Drag and drop music or video files here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func logoView(size: CGFloat, cornerRadius: CGFloat) -> some View {
        if let logo = AppLogo.image {
            Image(nsImage: logo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        } else {
            ZStack {
                Circle()
                    .fill(LinearGradient.brand)
                    .frame(width: size, height: size)
                    .opacity(0.15)
                Image(systemName: "music.note.list")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(LinearGradient.brand)
            }
        }
    }
}
