#!/usr/bin/swift

import AppKit
import Foundation

struct TopShelfArtwork {
    let filename: String
    let section: String
    let eyebrow: String
    let title: String
    let summary: String
    let symbolName: String
    let backgroundLeft: NSColor
    let backgroundCenter: NSColor
    let backgroundRight: NSColor
    let accentColor: NSColor
}

private let canvasSize = CGSize(width: 3840, height: 1440)
private let titleSafeLeftInset: CGFloat = 880
private let outputDirectory = URL(
    fileURLWithPath: CommandLine.arguments.contains("--output-dir")
        ? CommandLine.arguments[
            CommandLine.arguments.firstIndex(of: "--output-dir")!.advanced(by: 1)]
        : defaultOutputDirectoryPath()
)

private let assets: [TopShelfArtwork] = [
    .init(
        filename: "topshelf-klepon.png",
        section: "DISCOVER",
        eyebrow: "Featured sweet",
        title: "Klepon",
        summary:
            "A chewy rice cake with molten palm sugar and soft coconut that feels instantly comforting.",
        symbolName: "circle.hexagongrid.fill",
        backgroundLeft: NSColor(calibratedRed: 0.95, green: 0.91, blue: 0.82, alpha: 1),
        backgroundCenter: NSColor(calibratedRed: 0.63, green: 0.82, blue: 0.58, alpha: 1),
        backgroundRight: NSColor(calibratedRed: 0.14, green: 0.34, blue: 0.24, alpha: 1),
        accentColor: NSColor(calibratedRed: 0.89, green: 0.61, blue: 0.27, alpha: 1)
    ),
    .init(
        filename: "topshelf-rendang.png",
        section: "DISCOVER",
        eyebrow: "Deep and celebratory",
        title: "Rendang",
        summary:
            "Slow-cooked beef, coconut, and spice reduced into one of Indonesia's richest classics.",
        symbolName: "flame.fill",
        backgroundLeft: NSColor(calibratedRed: 0.51, green: 0.24, blue: 0.14, alpha: 1),
        backgroundCenter: NSColor(calibratedRed: 0.71, green: 0.35, blue: 0.20, alpha: 1),
        backgroundRight: NSColor(calibratedRed: 0.19, green: 0.10, blue: 0.08, alpha: 1),
        accentColor: NSColor(calibratedRed: 0.95, green: 0.74, blue: 0.44, alpha: 1)
    ),
    .init(
        filename: "topshelf-sambal.png",
        section: "DISCOVER",
        eyebrow: "Pantry essential",
        title: "Sambal",
        summary:
            "Bright, smoky, sweet, or sharp, sambal changes the whole plate with one spoonful.",
        symbolName: "leaf.fill",
        backgroundLeft: NSColor(calibratedRed: 0.81, green: 0.26, blue: 0.20, alpha: 1),
        backgroundCenter: NSColor(calibratedRed: 0.93, green: 0.46, blue: 0.27, alpha: 1),
        backgroundRight: NSColor(calibratedRed: 0.24, green: 0.12, blue: 0.08, alpha: 1),
        accentColor: NSColor(calibratedRed: 0.99, green: 0.82, blue: 0.53, alpha: 1)
    ),
    .init(
        filename: "topshelf-street-food.png",
        section: "DISCOVER",
        eyebrow: "Daily food rhythm",
        title: "Street food culture",
        summary:
            "Portable meals, market snacks, and fast comfort that shape how many people first meet Indonesian food.",
        symbolName: "sparkles",
        backgroundLeft: NSColor(calibratedRed: 0.22, green: 0.42, blue: 0.31, alpha: 1),
        backgroundCenter: NSColor(calibratedRed: 0.37, green: 0.60, blue: 0.44, alpha: 1),
        backgroundRight: NSColor(calibratedRed: 0.10, green: 0.17, blue: 0.13, alpha: 1),
        accentColor: NSColor(calibratedRed: 0.97, green: 0.84, blue: 0.60, alpha: 1)
    ),
]

do {
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    for asset in assets {
        let image = draw(asset: asset)
        let destination = outputDirectory.appendingPathComponent(asset.filename)
        guard
            let data = image.tiffRepresentation,
            let representation = NSBitmapImageRep(data: data),
            let png = representation.representation(using: .png, properties: [:])
        else {
            throw NSError(
                domain: "TopShelfGenerator",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode \(asset.filename)"]
            )
        }

        try png.write(to: destination, options: .atomic)
        print("wrote \(destination.path)")
    }
} catch {
    fputs("Top Shelf generation failed: \(error)\n", stderr)
    exit(1)
}

private func defaultOutputDirectoryPath() -> String {
    URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("KleponTVTopShelfExtension")
        .path
}

private func draw(asset: TopShelfArtwork) -> NSImage {
    let image = NSImage(size: canvasSize)
    image.lockFocusFlipped(true)
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current else {
        return image
    }

    context.shouldAntialias = true
    context.imageInterpolation = .high

    drawBackground(for: asset)
    drawForeground(for: asset)

    return image
}

private func drawBackground(for asset: TopShelfArtwork) {
    let fullRect = CGRect(origin: .zero, size: canvasSize)
    let gradient = NSGradient(colors: [
        asset.backgroundLeft, asset.backgroundCenter, asset.backgroundRight,
    ])!
    gradient.draw(in: fullRect, angle: 0)

    let topRightCircle = NSBezierPath(
        ovalIn: CGRect(x: canvasSize.width - 1120, y: -80, width: 1160, height: 1160)
    )
    NSColor(calibratedWhite: 1, alpha: 0.10).setFill()
    topRightCircle.fill()

    let rightGlow = NSBezierPath(
        ovalIn: CGRect(x: canvasSize.width - 1480, y: 260, width: 1240, height: 840)
    )
    asset.accentColor.withAlphaComponent(0.18).setFill()
    rightGlow.fill()

    let rightCard = NSBezierPath(
        roundedRect: CGRect(x: 2560, y: 240, width: 980, height: 700), xRadius: 82, yRadius: 82)
    NSColor(calibratedWhite: 1, alpha: 0.14).setFill()
    rightCard.fill()

    let innerCard = NSBezierPath(
        roundedRect: CGRect(x: 2680, y: 350, width: 620, height: 470), xRadius: 58, yRadius: 58)
    NSColor(calibratedWhite: 1, alpha: 0.08).setFill()
    innerCard.fill()

    let glowBar = NSBezierPath(
        roundedRect: CGRect(x: 2280, y: 510, width: 270, height: 260), xRadius: 110, yRadius: 110)
    NSColor(calibratedWhite: 1, alpha: 0.16).setFill()
    glowBar.fill()
}

private func drawForeground(for asset: TopShelfArtwork) {
    let leftInset = titleSafeLeftInset

    drawText(
        asset.section,
        in: CGRect(x: leftInset, y: 190, width: 420, height: 60),
        font: font(name: "Avenir Next Demi Bold", size: 42) ?? font(name: "Arial Bold", size: 42)!,
        color: NSColor(calibratedWhite: 1, alpha: 0.82),
        alignment: .left,
        uppercase: true
    )

    drawText(
        asset.eyebrow,
        in: CGRect(x: leftInset, y: 350, width: 980, height: 86),
        font: font(name: "Avenir Next Demi Bold", size: 60) ?? font(name: "Arial Bold", size: 60)!,
        color: NSColor(calibratedWhite: 1, alpha: 0.94),
        alignment: .left
    )

    drawText(
        asset.title,
        in: CGRect(x: leftInset, y: 480, width: 1560, height: 200),
        font: font(name: "Avenir Next Bold", size: 124) ?? font(name: "Arial Bold", size: 124)!,
        color: .white,
        alignment: .left
    )

    drawText(
        asset.summary,
        in: CGRect(x: leftInset, y: 720, width: 1700, height: 180),
        font: font(name: "Avenir Next Regular", size: 54) ?? font(name: "Arial", size: 54)!,
        color: NSColor(calibratedWhite: 1, alpha: 0.88),
        alignment: .left
    )

    let orbRect = CGRect(x: 2790, y: 365, width: 410, height: 410)
    let orb = NSBezierPath(ovalIn: orbRect)
    let orbGradient = NSGradient(colors: [
        asset.accentColor.withAlphaComponent(0.92),
        asset.accentColor.withAlphaComponent(0.64),
        NSColor(calibratedWhite: 1, alpha: 0.18),
    ])!
    orbGradient.draw(in: orb, angle: 45)

    let orbHighlight = NSBezierPath(ovalIn: CGRect(x: 2870, y: 440, width: 180, height: 120))
    NSColor(calibratedWhite: 1, alpha: 0.18).setFill()
    orbHighlight.fill()

    if let symbol = symbolImage(named: asset.symbolName, pointSize: 150, tint: .white) {
        symbol.draw(in: CGRect(x: 2915, y: 485, width: 160, height: 160))
    }
}

private func drawText(
    _ string: String,
    in rect: CGRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment,
    uppercase: Bool = false
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping

    let attributed = NSAttributedString(
        string: uppercase ? string.uppercased() : string,
        attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ]
    )

    attributed.draw(in: rect)
}

private func font(name: String, size: CGFloat) -> NSFont? {
    NSFont(name: name, size: size)
}

private func symbolImage(named name: String, pointSize: CGFloat, tint: NSColor) -> NSImage? {
    let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
    guard
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
    else {
        return nil
    }

    let tinted = image.copy() as? NSImage
    tinted?.lockFocus()
    tint.set()
    let imageRect = CGRect(origin: .zero, size: image.size)
    imageRect.fill(using: .sourceAtop)
    tinted?.unlockFocus()
    return tinted
}
