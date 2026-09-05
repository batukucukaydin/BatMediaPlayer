import SwiftUI

struct EqualizerView: View {
    let isPlaying: Bool
    var barCount: Int = 20
    var barWidth: CGFloat = 3
    var barSpacing: CGFloat = 2
    var color: Color = .brand
    var height: CGFloat = 44

    @State private var heights: [CGFloat] = []
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    init(isPlaying: Bool, barCount: Int = 20, barWidth: CGFloat = 3, barSpacing: CGFloat = 2, color: Color = .brand, height: CGFloat = 44) {
        self.isPlaying = isPlaying
        self.barCount = barCount
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        self.color = color
        self.height = height
        self._heights = State(initialValue: (0..<barCount).map { _ in CGFloat.random(in: 0.15...0.6) })
    }

    var body: some View {
        HStack(alignment: .center, spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
                    .fill(color)
                    .frame(width: barWidth, height: max(3, heights[i] * height))
            }
        }
        .onReceive(timer) { _ in
            guard isPlaying else { return }
            for i in 0..<barCount {
                heights[i] = CGFloat.random(in: 0.12...1.0)
            }
        }
        .onChange(of: isPlaying) { _, playing in
            if !playing, heights != heights.map({ _ in 0.12 }) {
                heights = heights.map { _ in 0.12 }
            }
        }
    }
}
