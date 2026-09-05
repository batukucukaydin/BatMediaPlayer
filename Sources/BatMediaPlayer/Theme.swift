import SwiftUI

extension Color {
    // Midnight listening room palette.
    static let ink = Color(red: 0.055, green: 0.06, blue: 0.12)
    static let surface = Color.white.opacity(0.055)
    static let surfaceElevated = Color.white.opacity(0.095)
    static let outline = Color.white.opacity(0.12)
    static let brand = Color(red: 0.48, green: 0.40, blue: 1.0)
    static let brandViolet = Color(red: 0.63, green: 0.30, blue: 0.98)
    static let brandPink = Color(red: 1.0, green: 0.30, blue: 0.48)
    static let brandAmber = Color(red: 1.0, green: 0.67, blue: 0.30)
}

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [.brand, .brandViolet, .brandPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Font {
    static let appDisplay = Font.system(size: 30, weight: .bold, design: .rounded)
    static let appTitle = Font.system(size: 19, weight: .bold, design: .rounded)
    static let appBody = Font.system(size: 13, weight: .regular, design: .rounded)
    static let appBodyMedium = Font.system(size: 13, weight: .medium, design: .rounded)
    static let appCaption = Font.system(size: 11, weight: .medium, design: .rounded)
    static let appMono = Font.system(size: 11, weight: .medium, design: .monospaced)
}

extension View {
    func listeningSurface(cornerRadius: CGFloat = 14) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.outline, lineWidth: 1)
                )
        )
    }
}

enum AppLogo {
    static var image: NSImage? {
        guard let url = Bundle.main.url(forResource: "baticon", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}
