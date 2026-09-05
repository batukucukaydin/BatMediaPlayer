import SwiftUI
import AVFoundation

struct PlayerControlsView: View {
    @EnvironmentObject var vm: PlayerViewModel
    @State private var isSeeking = false
    @State private var sliderValue: Double = 0

    private let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    private let sleepOptions: [Int] = [5, 10, 15, 30, 45, 60]

    var body: some View {
        VStack(spacing: 14) {
            seekBar
            transportRow
            utilityRow
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.outline).frame(height: 1)
        }
        .onChange(of: vm.currentTime) { _, newValue in
            if !isSeeking { sliderValue = newValue }
        }
        .onChange(of: vm.duration) { _, _ in
            if !isSeeking { sliderValue = vm.currentTime }
        }
    }

    // MARK: - Seek bar

    private var seekBar: some View {
        HStack(spacing: 12) {
            Text(formatTime(isSeeking ? sliderValue : vm.currentTime))
                .font(.appMono)
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)

            Slider(
                value: $sliderValue,
                in: 0...max(vm.duration, 1),
                onEditingChanged: { editing in
                    isSeeking = editing
                    if editing {
                        sliderValue = vm.currentTime
                    } else {
                        vm.seek(to: sliderValue)
                    }
                }
            )
            .disabled(vm.currentItem == nil)

            Text(formatTime(vm.duration))
                .font(.appMono)
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
        }
    }

    // MARK: - Transport

    private var transportRow: some View {
        HStack(spacing: 22) {
            IconButton(systemName: "shuffle", active: vm.shuffleEnabled, help: "Shuffle") {
                vm.toggleShuffle()
            }

            IconButton(systemName: "backward.fill", help: "Previous") {
                vm.previous()
            }

            playButton

            IconButton(systemName: "forward.fill", help: "Next") {
                vm.next()
            }

            IconButton(systemName: repeatIcon, active: vm.repeatMode != .off, help: repeatHelp) {
                vm.cycleRepeatMode()
            }
        }
        .disabled(vm.currentItem == nil)
        .opacity(vm.currentItem == nil ? 0.4 : 1)
    }

    private var playButton: some View {
        Button(action: { vm.togglePlayPause() }) {
            ZStack {
                Circle()
                    .fill(LinearGradient.brand)
                    .frame(width: 56, height: 56)
                    .shadow(color: .brand.opacity(0.5), radius: 14, y: 5)
                Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .offset(x: vm.isPlaying ? 0 : 2)
            }
        }
        .buttonStyle(.plain)
        .help("Play/Pause")
    }

    // MARK: - Utilities

    private var utilityRow: some View {
        HStack(spacing: 18) {
            HStack(spacing: 8) {
                Button(action: { vm.setVolume(vm.volume > 0 ? 0 : 0.5) }) {
                    Image(systemName: volumeIcon)
                        .frame(width: 22)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Volume")

                Slider(
                    value: Binding(
                        get: { Double(vm.volume) },
                        set: { vm.setVolume(Float($0)) }
                    ),
                    in: 0...1
                )
                .frame(width: 120)
            }

            if let upNext = vm.upNextTitle {
                HStack(spacing: 5) {
                    Image(systemName: "forward.end")
                        .font(.caption2)
                    Text("\(String(localized: "Up Next")): \(upNext)")
                }
                .font(.appCaption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 220)
            }

            Spacer(minLength: 8)

            // The utility set is wider than a compact detail column. Keep it
            // accessible instead of letting SwiftUI push buttons off-screen.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    loopButton
                    chapterMenu
                    trackMenu
                    screenshotButton
                    IconButton(systemName: "stop.fill", help: "Stop") {
                        vm.stop()
                    }
                    speedMenu
                    sleepMenu
                }
            }
            .frame(maxWidth: 360)
        }
    }

    private var loopButton: some View {
        Button { vm.setLoopPoint() } label: {
            HStack(spacing: 4) {
                Image(systemName: "repeat")
                    .foregroundColor(vm.loopActive ? .brand : .secondary)
                if vm.loopActive {
                    Text("A–B").font(.caption).monospacedDigit().foregroundColor(.brand)
                }
            }
            .font(.callout)
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .help(vm.loopLabel)
    }

    @ViewBuilder
    private var chapterMenu: some View {
        if !vm.chapters.isEmpty {
            Menu {
                ForEach(Array(vm.chapters.enumerated()), id: \.element.id) { i, ch in
                    Button("\(i + 1). \(ch.title)") { vm.jump(to: ch.time) }
                }
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Chapters")
        }
    }

    @ViewBuilder
    private var trackMenu: some View {
        if !vm.subtitleOptions.isEmpty || !vm.audioOptions.isEmpty {
            Menu {
                if !vm.subtitleOptions.isEmpty {
                    Text("Subtitles").font(.caption).foregroundColor(.secondary)
                    Button("Off") { vm.selectSubtitle(-1) }
                    ForEach(Array(vm.subtitleOptions.enumerated()), id: \.offset) { i, opt in
                        Button(optionLabel(opt)) {
                            vm.selectSubtitle(i)
                        }
                    }
                }
                if !vm.audioOptions.isEmpty {
                    Divider()
                    Text("Audio").font(.caption).foregroundColor(.secondary)
                    ForEach(Array(vm.audioOptions.enumerated()), id: \.offset) { i, opt in
                        Button(optionLabel(opt)) {
                            vm.selectAudio(i)
                        }
                    }
                }
            } label: {
                Image(systemName: "captions.bubble")
                    .font(.callout)
                    .foregroundColor(vm.selectedSubtitleIndex != nil ? .brand : .secondary)
            }
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Subtitles & Audio")
        }
    }

    private var screenshotButton: some View {
        Button { vm.captureCurrentFrame() } label: {
            Image(systemName: "camera")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .help("Screenshot")
        .disabled(vm.currentItem == nil)
    }

    private func optionLabel(_ opt: AVMediaSelectionOption) -> String {
        var tag = ""
        if let lang = opt.extendedLanguageTag { tag = "  (\(lang))" }
        return opt.displayName + tag
    }

    private var speedMenu: some View {
        Menu {
            ForEach(speeds, id: \.self) { s in
                Button(speedLabel(s)) { vm.setRate(s) }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "gauge")
                Text(speedLabel(vm.rate))
            }
            .font(.callout)
            .foregroundColor(.secondary)
        }
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var sleepMenu: some View {
        Menu {
            Button("Sleep Timer: Off") { vm.cancelSleepTimer() }
            Divider()
            ForEach(sleepOptions, id: \.self) { m in
                Button("\(m) \(String(localized: "min"))") { vm.setSleepTimer(minutes: m) }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "moon.zzz.fill")
                    .foregroundColor(vm.sleepRemainingSeconds > 0 ? .brand : .secondary)
                if vm.sleepRemainingSeconds > 0 {
                    Text(vm.sleepRemainingLabel)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.brand)
                }
            }
            .font(.callout)
        }
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - Helpers

    private var repeatIcon: String {
        vm.repeatMode == .one ? "repeat.1" : "repeat"
    }

    private var repeatHelp: String {
        switch vm.repeatMode {
        case .off: return String(localized: "Repeat Off")
        case .all: return String(localized: "Repeat All")
        case .one: return String(localized: "Repeat One")
        }
    }

    private var volumeIcon: String {
        if vm.volume == 0 { return "speaker.slash.fill" }
        if vm.volume < 0.34 { return "speaker.wave.1.fill" }
        if vm.volume < 0.67 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }

    private func speedLabel(_ s: Float) -> String {
        if s == 1.0 { return String(localized: "Normal") }
        return String(format: "%.2g×", s)
    }
}

struct IconButton: View {
    let systemName: String
    var active: Bool = false
    var help: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(active ? .brand : .primary)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(active ? Color.brand.opacity(0.22) : Color.surface)
                        .overlay(Circle().stroke(Color.outline, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
