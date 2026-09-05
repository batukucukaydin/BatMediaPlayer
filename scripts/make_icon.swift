import AppKit

func makeIcon(pixelSize: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    guard let gctx = NSGraphicsContext(bitmapImageRep: rep) else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
    NSGraphicsContext.current = gctx
    let ctx = gctx.cgContext

    let s = CGFloat(pixelSize) / 1024.0
    ctx.scaleBy(x: s, y: s)

    // Background rounded rect
    let rect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    let corner = 1024 * 0.224
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil))
    ctx.clip()

    // Gradient background
    let c1 = NSColor(calibratedRed: 0.388, green: 0.400, blue: 0.945, alpha: 1).cgColor // #6366F1
    let c2 = NSColor(calibratedRed: 0.753, green: 0.149, blue: 0.827, alpha: 1).cgColor // #C026D3
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [c1, c2] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1024, y: 1024), options: [])

    // Vinyl-like disc
    let discRect = CGRect(x: 512 - 360, y: 512 - 360, width: 720, height: 720)
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.14).cgColor)
    ctx.fillEllipse(in: discRect)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.30).cgColor)
    ctx.setLineWidth(22)
    ctx.strokeEllipse(in: discRect)

    // Play triangle
    let cx: CGFloat = 512 - 20
    let cy: CGFloat = 512
    let hw: CGFloat = 190
    let hh: CGFloat = 230
    let tri = CGMutablePath()
    tri.move(to: CGPoint(x: cx - hw, y: cy - hh))
    tri.addLine(to: CGPoint(x: cx - hw, y: cy + hh))
    tri.addLine(to: CGPoint(x: cx + hw, y: cy))
    tri.closeSubpath()

    ctx.setFillColor(NSColor.white.cgColor)
    ctx.addPath(tri)
    ctx.fillPath()

    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(40)
    ctx.setLineJoin(.round)
    ctx.setLineCap(.round)
    ctx.addPath(tri)
    ctx.strokePath()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.iconset"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let spec: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in spec {
    if let data = makeIcon(pixelSize: size) {
        let url = URL(fileURLWithPath: outputDir).appendingPathComponent(name)
        try? data.write(to: url)
    }
}

print("iconset written to \(outputDir)")
