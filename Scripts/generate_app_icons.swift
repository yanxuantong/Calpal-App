import AppKit
import Foundation

struct Palette {
    let background: NSColor
    let shadow: NSColor
    let calendarBody: NSColor
    let calendarTop: NSColor
    let detail: NSColor
    let sparkPrimary: NSColor
    let sparkSecondary: NSColor
}

let outputDirectory = URL(fileURLWithPath: "/Users/xuantongyan/Documents/Projects/Calpal-Codex/Calpal-Codex/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

let light = Palette(
    background: NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.0, alpha: 1),
    shadow: NSColor(calibratedWhite: 0.05, alpha: 0.10),
    calendarBody: NSColor.white,
    calendarTop: NSColor(calibratedRed: 0.12, green: 0.42, blue: 0.98, alpha: 1),
    detail: NSColor(calibratedRed: 0.10, green: 0.16, blue: 0.28, alpha: 1),
    sparkPrimary: NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.18, alpha: 1),
    sparkSecondary: NSColor(calibratedRed: 1.0, green: 0.96, blue: 0.75, alpha: 1)
)

let dark = Palette(
    background: NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.12, alpha: 1),
    shadow: NSColor(calibratedWhite: 0.0, alpha: 0.28),
    calendarBody: NSColor(calibratedRed: 0.12, green: 0.16, blue: 0.22, alpha: 1),
    calendarTop: NSColor(calibratedRed: 0.27, green: 0.72, blue: 1.0, alpha: 1),
    detail: NSColor(calibratedRed: 0.92, green: 0.95, blue: 1.0, alpha: 1),
    sparkPrimary: NSColor(calibratedRed: 1.0, green: 0.84, blue: 0.20, alpha: 1),
    sparkSecondary: NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.72, alpha: 1)
)

let tinted = Palette(
    background: NSColor.black,
    shadow: NSColor.clear,
    calendarBody: NSColor.white,
    calendarTop: NSColor.white,
    detail: NSColor.black,
    sparkPrimary: NSColor.white,
    sparkSecondary: NSColor.white
)

func drawSpark(in rect: CGRect, palette: Palette) {
    let outer = NSBezierPath()
    outer.move(to: CGPoint(x: rect.midX, y: rect.maxY))
    outer.line(to: CGPoint(x: rect.maxX, y: rect.midY))
    outer.line(to: CGPoint(x: rect.midX, y: rect.minY))
    outer.line(to: CGPoint(x: rect.minX, y: rect.midY))
    outer.close()
    palette.sparkPrimary.setFill()
    outer.fill()

    let innerRect = rect.insetBy(dx: rect.width * 0.24, dy: rect.height * 0.24)
    let inner = NSBezierPath()
    inner.move(to: CGPoint(x: innerRect.midX, y: innerRect.maxY))
    inner.line(to: CGPoint(x: innerRect.maxX, y: innerRect.midY))
    inner.line(to: CGPoint(x: innerRect.midX, y: innerRect.minY))
    inner.line(to: CGPoint(x: innerRect.minX, y: innerRect.midY))
    inner.close()
    palette.sparkSecondary.setFill()
    inner.fill()
}

func renderIcon(size: CGFloat, palette: Palette, monochrome: Bool = false) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let canvas = CGRect(x: 0, y: 0, width: size, height: size)
    let backgroundPath = NSBezierPath(roundedRect: canvas, xRadius: size * 0.23, yRadius: size * 0.23)
    palette.background.setFill()
    backgroundPath.fill()

    let shadowRect = CGRect(x: size * 0.13, y: size * 0.18, width: size * 0.62, height: size * 0.60)
    let shadowPath = NSBezierPath(roundedRect: shadowRect, xRadius: size * 0.09, yRadius: size * 0.09)
    palette.shadow.setFill()
    shadowPath.fill()

    let calendarRect = CGRect(x: size * 0.11, y: size * 0.20, width: size * 0.62, height: size * 0.60)
    let calendarPath = NSBezierPath(roundedRect: calendarRect, xRadius: size * 0.09, yRadius: size * 0.09)
    palette.calendarBody.setFill()
    calendarPath.fill()

    let topRect = CGRect(x: calendarRect.minX, y: calendarRect.maxY - size * 0.16, width: calendarRect.width, height: size * 0.16)
    let topPath = NSBezierPath(roundedRect: topRect, xRadius: size * 0.09, yRadius: size * 0.09)
    palette.calendarTop.setFill()
    topPath.fill()

    let separator = NSBezierPath()
    separator.move(to: CGPoint(x: calendarRect.minX + size * 0.08, y: calendarRect.midY + size * 0.07))
    separator.line(to: CGPoint(x: calendarRect.maxX - size * 0.08, y: calendarRect.midY + size * 0.07))
    separator.lineWidth = size * 0.020
    palette.detail.withAlphaComponent(monochrome ? 0.55 : 0.16).setStroke()
    separator.stroke()

    for row in 0..<2 {
        for col in 0..<2 {
            let dotRect = CGRect(
                x: calendarRect.minX + size * 0.11 + CGFloat(col) * size * 0.18,
                y: calendarRect.minY + size * 0.14 + CGFloat(row) * size * 0.15,
                width: size * 0.07,
                height: size * 0.07
            )
            let dotPath = NSBezierPath(roundedRect: dotRect, xRadius: size * 0.018, yRadius: size * 0.018)
            (monochrome ? palette.detail.withAlphaComponent(0.82) : palette.detail.withAlphaComponent(0.86)).setFill()
            dotPath.fill()
        }
    }

    let ringColor = monochrome ? NSColor.white : palette.sparkPrimary
    ringColor.setStroke()
    let ring = NSBezierPath()
    ring.lineWidth = size * 0.030
    ring.move(to: CGPoint(x: size * 0.68, y: size * 0.74))
    ring.line(to: CGPoint(x: size * 0.83, y: size * 0.89))
    ring.stroke()

    drawSpark(
        in: CGRect(x: size * 0.66, y: size * 0.61, width: size * 0.22, height: size * 0.22),
        palette: palette
    )

    image.unlockFocus()
    return image
}

func pngData(for image: NSImage, size: CGFloat) -> Data? {
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
        return nil
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()

    return bitmap.representation(using: .png, properties: [:])
}

func writeIcon(named name: String, size: CGFloat, palette: Palette, monochrome: Bool = false) throws {
    let image = renderIcon(size: size, palette: palette, monochrome: monochrome)
    guard let data = pngData(for: image, size: size) else {
        throw NSError(domain: "IconGen", code: 1)
    }
    try data.write(to: outputDirectory.appendingPathComponent(name))
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

try writeIcon(named: "ios-1024-light.png", size: 1024, palette: light)
try writeIcon(named: "ios-1024-dark.png", size: 1024, palette: dark)
try writeIcon(named: "ios-1024-tinted.png", size: 1024, palette: tinted, monochrome: true)

let macSpecs: [(String, CGFloat)] = [
    ("mac-16.png", 16),
    ("mac-16@2x.png", 32),
    ("mac-32.png", 32),
    ("mac-32@2x.png", 64),
    ("mac-128.png", 128),
    ("mac-128@2x.png", 256),
    ("mac-256.png", 256),
    ("mac-256@2x.png", 512),
    ("mac-512.png", 512),
    ("mac-512@2x.png", 1024)
]

for (name, size) in macSpecs {
    try writeIcon(named: name, size: size, palette: light)
}

print("Generated app icons in \(outputDirectory.path)")
