#!/usr/bin/swift

import AppKit
import Foundation

private let bundleIdentifier = "ai.splitfire.klepon"
private let catalogName = "AppIconTV.brandassets"
private let outputDirectory = URL(
    fileURLWithPath: CommandLine.arguments.contains("--output-dir")
        ? CommandLine.arguments[
            CommandLine.arguments.firstIndex(of: "--output-dir")!.advanced(by: 1)]
        : defaultOutputDirectoryPath()
)

private let backgroundColor = NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.92, alpha: 1)
private let surfaceColor = NSColor(calibratedRed: 0.98, green: 0.95, blue: 0.89, alpha: 1)
private let surfaceSecondaryColor = NSColor(calibratedRed: 0.93, green: 0.90, blue: 0.84, alpha: 1)
private let accentColor = NSColor(calibratedRed: 0.17, green: 0.48, blue: 0.34, alpha: 1)
private let accentLightColor = NSColor(calibratedRed: 0.46, green: 0.78, blue: 0.56, alpha: 1)
private let accentDarkColor = NSColor(calibratedRed: 0.12, green: 0.34, blue: 0.23, alpha: 1)
private let warmColor = NSColor(calibratedRed: 0.56, green: 0.35, blue: 0.17, alpha: 1)
private let warmLightColor = NSColor(calibratedRed: 0.90, green: 0.60, blue: 0.25, alpha: 1)
private let textPrimaryColor = NSColor(calibratedRed: 0.17, green: 0.16, blue: 0.13, alpha: 1)
private let textSecondaryColor = NSColor(calibratedRed: 0.37, green: 0.35, blue: 0.31, alpha: 1)
private let dividerColor = NSColor(calibratedWhite: 0, alpha: 0.08)
private let coconutColor = NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.94, alpha: 1)
private let coconutShadowColor = NSColor(calibratedRed: 0.88, green: 0.85, blue: 0.76, alpha: 0.72)

private let coconutFlakes: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
    (0.16, 0.34, 0.050, 0.026, -18),
    (0.19, 0.31, 0.042, 0.024, 12),
    (0.22, 0.28, 0.052, 0.028, -8),
    (0.25, 0.25, 0.044, 0.025, 9),
    (0.28, 0.22, 0.055, 0.028, -12),
    (0.32, 0.19, 0.048, 0.026, 14),
    (0.36, 0.16, 0.056, 0.030, -10),
    (0.41, 0.13, 0.046, 0.026, 6),
    (0.46, 0.11, 0.054, 0.029, -14),
    (0.51, 0.10, 0.043, 0.024, 11),
    (0.56, 0.11, 0.051, 0.028, -9),
    (0.61, 0.13, 0.046, 0.025, 13),
    (0.66, 0.17, 0.056, 0.030, -11),
    (0.70, 0.20, 0.050, 0.027, 8),
    (0.74, 0.24, 0.047, 0.026, -7),
    (0.77, 0.28, 0.055, 0.029, 12),
    (0.80, 0.32, 0.048, 0.026, -9),
    (0.24, 0.37, 0.032, 0.020, -6),
    (0.29, 0.34, 0.034, 0.021, 13),
    (0.35, 0.30, 0.033, 0.020, -10),
    (0.40, 0.26, 0.035, 0.022, 5),
    (0.47, 0.23, 0.032, 0.020, -15),
    (0.54, 0.22, 0.034, 0.021, 7),
    (0.60, 0.24, 0.033, 0.020, -8),
    (0.67, 0.28, 0.035, 0.022, 14),
    (0.72, 0.33, 0.032, 0.020, -11),
]

private let smallIconCanvas = CGSize(width: 400, height: 240)
private let appStoreCanvas = CGSize(width: 1280, height: 768)
private let topShelfCanvas = CGSize(width: 1920, height: 720)
private let topShelfWideCanvas = CGSize(width: 2320, height: 720)

do {
    try regenerateCatalog()
} catch {
    fputs("tvOS brand asset generation failed: \(error)\n", stderr)
    exit(1)
}

private func regenerateCatalog() throws {
    if FileManager.default.fileExists(atPath: outputDirectory.path) {
        try FileManager.default.removeItem(at: outputDirectory)
    }

    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    try writeRootContents()
    try writePrimaryIconStack(
        name: "App Icon - tvOS", canvas: smallIconCanvas, scales: [1, 2], includeFrameSize: true)
    try writePrimaryIconStack(
        name: "App Icon - tvOS - App Store", canvas: appStoreCanvas, scales: [1],
        includeFrameSize: false)
    try writeTopShelfImageSet(
        name: "Top Shelf Image", canvas: topShelfCanvas, baseFileName: "TopShelfImage")
    try writeTopShelfImageSet(
        name: "Top Shelf Image Wide", canvas: topShelfWideCanvas, baseFileName: "TopShelfImageWide")
}

private func defaultOutputDirectoryPath() -> String {
    let cwd = FileManager.default.currentDirectoryPath
    return URL(fileURLWithPath: cwd)
        .appendingPathComponent("Klepon/Assets.xcassets/\(catalogName)")
        .path
}

private func writeRootContents() throws {
    try writeJSON(
        [
            "assets": [
                [
                    "idiom": "tv",
                    "filename": "App Icon - tvOS - App Store.imagestack",
                    "role": "primary-app-icon",
                    "size": "1280x768",
                ],
                [
                    "idiom": "tv",
                    "filename": "App Icon - tvOS.imagestack",
                    "role": "primary-app-icon",
                    "size": "400x240",
                ],
                [
                    "idiom": "tv",
                    "filename": "Top Shelf Image.imageset",
                    "role": "top-shelf-image",
                    "size": "1920x720",
                ],
                [
                    "idiom": "tv",
                    "filename": "Top Shelf Image Wide.imageset",
                    "role": "top-shelf-image-wide",
                    "size": "2320x720",
                ],
            ],
            "info": [
                "author": bundleIdentifier,
                "version": 1,
            ],
        ],
        to: outputDirectory.appendingPathComponent("Contents.json")
    )
}

private func writePrimaryIconStack(
    name: String, canvas: CGSize, scales: [Int], includeFrameSize: Bool
) throws {
    let stackFolder = outputDirectory.appendingPathComponent("\(name).imagestack")
    try FileManager.default.createDirectory(at: stackFolder, withIntermediateDirectories: true)

    try writeJSON(
        [
            "info": [
                "author": bundleIdentifier,
                "version": 1,
            ],
            "layers": [
                ["filename": "Front.imagestacklayer"],
                ["filename": "Back.imagestacklayer"],
            ],
        ],
        to: stackFolder.appendingPathComponent("Contents.json")
    )

    try writeLayer(
        folder: stackFolder.appendingPathComponent("Front.imagestacklayer"),
        imageSetName: "Content",
        imageBaseName: "Front",
        canvas: canvas,
        scales: scales,
        includeFrameSize: includeFrameSize,
        render: { try renderIconFront(canvas: $0) }
    )

    try writeLayer(
        folder: stackFolder.appendingPathComponent("Back.imagestacklayer"),
        imageSetName: "Content",
        imageBaseName: "Back",
        canvas: canvas,
        scales: scales,
        includeFrameSize: includeFrameSize,
        render: { try renderIconBack(canvas: $0) }
    )
}

private func writeLayer(
    folder: URL,
    imageSetName: String,
    imageBaseName: String,
    canvas: CGSize,
    scales: [Int],
    includeFrameSize: Bool,
    render: (CGSize) throws -> Data
) throws {
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

    var object: [String: Any] = [
        "info": [
            "author": bundleIdentifier,
            "version": 1,
        ]
    ]

    if includeFrameSize {
        object["properties"] = [
            "frame-size": [
                "width": Int(canvas.width),
                "height": Int(canvas.height),
            ]
        ]
    }

    try writeJSON(object, to: folder.appendingPathComponent("Contents.json"))

    try writeImageSet(
        folder: folder.appendingPathComponent("\(imageSetName).imageset"),
        baseName: imageBaseName,
        canvas: canvas,
        scales: scales,
        render: render
    )
}

private func writeTopShelfImageSet(name: String, canvas: CGSize, baseFileName: String) throws {
    try writeImageSet(
        folder: outputDirectory.appendingPathComponent("\(name).imageset"),
        baseName: baseFileName,
        canvas: canvas,
        scales: [1, 2],
        render: { try renderTopShelf(canvas: $0, isWide: name.contains("Wide")) }
    )
}

private func writeImageSet(
    folder: URL,
    baseName: String,
    canvas: CGSize,
    scales: [Int],
    render: (CGSize) throws -> Data
) throws {
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

    var imageEntries: [[String: String]] = []

    for scale in scales {
        let scaledCanvas = CGSize(
            width: canvas.width * CGFloat(scale), height: canvas.height * CGFloat(scale))
        let fileName = scale == 1 ? "\(baseName).png" : "\(baseName)@\(scale)x.png"
        let png = try render(scaledCanvas)
        try png.write(to: folder.appendingPathComponent(fileName), options: .atomic)

        var entry: [String: String] = [
            "filename": fileName,
            "idiom": "tv",
        ]

        if scales.count > 1 {
            entry["scale"] = "\(scale)x"
        }

        imageEntries.append(entry)
    }

    try writeJSON(
        [
            "images": imageEntries,
            "info": [
                "author": bundleIdentifier,
                "version": 1,
            ],
        ],
        to: folder.appendingPathComponent("Contents.json")
    )
}

private func renderIconBack(canvas: CGSize) throws -> Data {
    try renderPNG(canvas: canvas, opaque: true) { rect in
        drawWarmBackdrop(in: rect)

        let cardRect = CGRect(
            x: rect.minX + rect.width * 0.08,
            y: rect.minY + rect.height * 0.08,
            width: rect.width * 0.84,
            height: rect.height * 0.84
        )
        drawCard(in: cardRect, canvas: canvas)

        let haloRect = CGRect(
            x: rect.midX - rect.height * 0.23,
            y: rect.minY + rect.height * 0.24,
            width: rect.height * 0.46,
            height: rect.height * 0.46
        )
        let halo = NSBezierPath(ovalIn: haloRect)
        NSColor(calibratedRed: 0.46, green: 0.78, blue: 0.56, alpha: 0.12).setFill()
        halo.fill()
    }
}

private func renderIconFront(canvas: CGSize) throws -> Data {
    try renderPNG(canvas: canvas) { rect in
        let orbSize = min(rect.height * 0.70, rect.width * 0.54)
        let orbRect = CGRect(
            x: rect.midX - orbSize / 2,
            y: rect.minY + rect.height * 0.18,
            width: orbSize,
            height: orbSize
        )
        drawKlepon(in: orbRect, canvas: canvas, shadowAlpha: 0.34)
    }
}

private func renderTopShelf(canvas: CGSize, isWide: Bool) throws -> Data {
    try renderPNG(canvas: canvas, opaque: true) { rect in
        drawWarmBackdrop(in: rect)

        let wave = NSBezierPath()
        wave.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.14))
        wave.curve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.22),
            controlPoint1: CGPoint(
                x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.04),
            controlPoint2: CGPoint(
                x: rect.minX + rect.width * 0.68, y: rect.minY + rect.height * 0.30)
        )
        wave.line(to: CGPoint(x: rect.maxX, y: rect.minY))
        wave.line(to: CGPoint(x: rect.minX, y: rect.minY))
        wave.close()
        NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.24).setFill()
        wave.fill()

        let orbGlow = NSBezierPath(
            ovalIn: CGRect(
                x: rect.maxX - rect.height * 0.78,
                y: rect.midY - rect.height * 0.34,
                width: rect.height * 0.92,
                height: rect.height * 0.92
            ))
        NSColor(calibratedRed: 0.46, green: 0.78, blue: 0.56, alpha: 0.10).setFill()
        orbGlow.fill()

        let titleWidth = isWide ? rect.width * 0.30 : rect.width * 0.34
        drawText(
            "Taste of Indonesia",
            in: CGRect(
                x: rect.width * 0.10, y: rect.height * 0.62, width: titleWidth,
                height: rect.height * 0.10),
            font: font(name: "Avenir Next Demi Bold", size: rect.height * 0.09)
                ?? NSFont.systemFont(ofSize: rect.height * 0.09, weight: .semibold),
            color: textSecondaryColor
        )

        drawText(
            "Klepon",
            in: CGRect(
                x: rect.width * 0.10, y: rect.height * 0.38, width: rect.width * 0.30,
                height: rect.height * 0.18),
            font: font(name: "Avenir Next Bold", size: rect.height * 0.20)
                ?? NSFont.boldSystemFont(ofSize: rect.height * 0.20),
            color: textPrimaryColor
        )

        drawText(
            "Dishes   Ingredients   Traditions",
            in: CGRect(
                x: rect.width * 0.10, y: rect.height * 0.26, width: rect.width * 0.46,
                height: rect.height * 0.08),
            font: font(name: "Avenir Next Regular", size: rect.height * 0.075)
                ?? NSFont.systemFont(ofSize: rect.height * 0.075),
            color: textSecondaryColor
        )

        let cardWidth = isWide ? rect.width * 0.18 : rect.width * 0.23
        let cardRect = CGRect(
            x: rect.maxX - cardWidth - rect.width * 0.16,
            y: rect.midY - rect.height * 0.28,
            width: cardWidth,
            height: rect.height * 0.56
        )
        drawCard(in: cardRect, canvas: canvas)

        let secondaryCard = NSBezierPath(
            roundedRect: CGRect(
                x: cardRect.minX - cardRect.width * 0.18,
                y: cardRect.minY + cardRect.height * 0.18,
                width: cardRect.width * 0.34,
                height: cardRect.height * 0.48
            ), xRadius: cardRect.width * 0.11, yRadius: cardRect.width * 0.11)
        NSColor(calibratedWhite: 1, alpha: 0.28).setFill()
        secondaryCard.fill()

        let tertiaryCard = NSBezierPath(
            roundedRect: CGRect(
                x: cardRect.maxX - cardRect.width * 0.02,
                y: cardRect.minY + cardRect.height * 0.08,
                width: cardRect.width * 0.26,
                height: cardRect.height * 0.36
            ), xRadius: cardRect.width * 0.09, yRadius: cardRect.width * 0.09)
        NSColor(calibratedWhite: 1, alpha: 0.18).setFill()
        tertiaryCard.fill()

        let orbSize = min(cardRect.width * 0.68, cardRect.height * 0.68)
        let orbRect = CGRect(
            x: cardRect.midX - orbSize / 2,
            y: cardRect.minY + cardRect.height * 0.24,
            width: orbSize,
            height: orbSize
        )
        drawKlepon(in: orbRect, canvas: canvas, shadowAlpha: 0.28)
    }
}

private func drawWarmBackdrop(in rect: CGRect) {
    let background = NSGradient(colors: [
        NSColor(calibratedRed: 0.99, green: 0.97, blue: 0.94, alpha: 1),
        backgroundColor,
        NSColor(calibratedRed: 0.95, green: 0.91, blue: 0.84, alpha: 1),
    ])!
    background.draw(in: rect, angle: 0)

    let topGlow = NSBezierPath(
        ovalIn: CGRect(
            x: rect.minX - rect.width * 0.08,
            y: rect.maxY - rect.height * 0.46,
            width: rect.width * 0.52,
            height: rect.height * 0.52
        ))
    NSColor(calibratedWhite: 1, alpha: 0.14).setFill()
    topGlow.fill()

    let rightGlow = NSBezierPath(
        ovalIn: CGRect(
            x: rect.maxX - rect.width * 0.26,
            y: rect.minY + rect.height * 0.18,
            width: rect.width * 0.24,
            height: rect.height * 0.44
        ))
    NSColor(calibratedRed: 0.90, green: 0.76, blue: 0.42, alpha: 0.10).setFill()
    rightGlow.fill()
}

private func drawCard(in rect: CGRect, canvas: CGSize) {
    let radius = min(rect.width, rect.height) * 0.18
    let card = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let cardGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.99, green: 0.97, blue: 0.93, alpha: 1),
        surfaceColor,
        surfaceSecondaryColor,
    ])!
    cardGradient.draw(in: card, angle: 90)

    dividerColor.setStroke()
    card.lineWidth = max(1, canvas.width * 0.0016)
    card.stroke()

    let innerGlow = NSBezierPath(
        roundedRect: rect.insetBy(dx: rect.width * 0.02, dy: rect.height * 0.02),
        xRadius: radius * 0.92, yRadius: radius * 0.92)
    NSColor(calibratedWhite: 1, alpha: 0.22).setStroke()
    innerGlow.lineWidth = max(1.5, canvas.width * 0.0022)
    innerGlow.stroke()

    NSGraphicsContext.saveGraphicsState()
    card.addClip()
    let cornerGlow = NSGradient(colors: [
        NSColor(calibratedWhite: 1, alpha: 0.24),
        NSColor(calibratedWhite: 1, alpha: 0),
    ])!
    cornerGlow.draw(
        fromCenter: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.maxY - rect.height * 0.18),
        radius: rect.width * 0.58,
        toCenter: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.maxY - rect.height * 0.18),
        radius: 0,
        options: []
    )
    NSGraphicsContext.restoreGraphicsState()
}

private func drawKlepon(in orbRect: CGRect, canvas: CGSize, shadowAlpha: CGFloat) {
    let shadowRect = CGRect(
        x: orbRect.minX + orbRect.width * 0.06,
        y: orbRect.minY - orbRect.height * 0.12,
        width: orbRect.width * 0.88,
        height: orbRect.height * 0.26
    )
    let shadow = NSBezierPath(ovalIn: shadowRect)
    NSColor(calibratedRed: 0.37, green: 0.24, blue: 0.10, alpha: shadowAlpha).setFill()
    shadow.fill()

    let orb = NSBezierPath(ovalIn: orbRect)
    let orbGradient = NSGradient(colors: [
        accentLightColor, accentColor,
        NSColor(calibratedRed: 0.28, green: 0.58, blue: 0.40, alpha: 1),
    ])!
    orbGradient.draw(in: orb, angle: 18)

    let shade = NSBezierPath(
        ovalIn: CGRect(
            x: orbRect.minX + orbRect.width * 0.06,
            y: orbRect.minY + orbRect.height * 0.10,
            width: orbRect.width * 0.74,
            height: orbRect.height * 0.70
        ))
    let shadeGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.06, green: 0.18, blue: 0.12, alpha: 0.26),
        NSColor(calibratedRed: 0.06, green: 0.18, blue: 0.12, alpha: 0),
    ])!
    shadeGradient.draw(in: shade, relativeCenterPosition: NSPoint(x: -0.3, y: -0.1))

    let highlight = NSBezierPath(
        ovalIn: CGRect(
            x: orbRect.minX + orbRect.width * 0.16,
            y: orbRect.minY + orbRect.height * 0.58,
            width: orbRect.width * 0.30,
            height: orbRect.height * 0.18
        ))
    let highlightGradient = NSGradient(colors: [
        NSColor(calibratedWhite: 1, alpha: 0.28),
        NSColor(calibratedWhite: 1, alpha: 0),
    ])!
    highlightGradient.draw(in: highlight, angle: 0)

    drawLeaves(around: orbRect, canvas: canvas)
    drawPalmSugar(in: orbRect, canvas: canvas)
    drawCoconutFlakes(in: orbRect, canvas: canvas)
}

private func drawLeaves(around orbRect: CGRect, canvas: CGSize) {
    let darkLeafRect = CGRect(
        x: orbRect.maxX - orbRect.width * 0.28,
        y: orbRect.maxY - orbRect.height * 0.18,
        width: orbRect.width * 0.22,
        height: orbRect.height * 0.22
    )
    let darkLeaf = NSBezierPath(ovalIn: darkLeafRect)
    accentDarkColor.setFill()
    darkLeaf.fill()

    let lightLeafRect = CGRect(
        x: orbRect.maxX - orbRect.width * 0.34,
        y: orbRect.maxY - orbRect.height * 0.23,
        width: orbRect.width * 0.18,
        height: orbRect.height * 0.18
    )
    let lightLeaf = NSBezierPath(ovalIn: lightLeafRect)
    NSColor(calibratedRed: 0.30, green: 0.62, blue: 0.39, alpha: 1).setFill()
    lightLeaf.fill()

    let stem = NSBezierPath()
    stem.move(
        to: CGPoint(x: orbRect.maxX - orbRect.width * 0.16, y: orbRect.maxY - orbRect.height * 0.08)
    )
    stem.line(
        to: CGPoint(x: orbRect.maxX - orbRect.width * 0.16, y: orbRect.maxY - orbRect.height * 0.34)
    )
    stem.lineCapStyle = .round
    stem.lineWidth = max(2.2, canvas.width * 0.006)
    NSColor(calibratedRed: 0.23, green: 0.56, blue: 0.33, alpha: 1).setStroke()
    stem.stroke()
}

private func drawPalmSugar(in orbRect: CGRect, canvas: CGSize) {
    let sugarSize = orbRect.width * 0.24
    let sugarRect = CGRect(
        x: orbRect.midX - sugarSize / 2,
        y: orbRect.midY - sugarSize / 2 + orbRect.height * 0.02,
        width: sugarSize,
        height: sugarSize
    )
    let sugarGlow = NSBezierPath(
        ovalIn: sugarRect.insetBy(dx: -sugarSize * 0.16, dy: -sugarSize * 0.16))
    NSColor(calibratedRed: 0.24, green: 0.14, blue: 0.06, alpha: 0.28).setFill()
    sugarGlow.fill()

    let sugar = NSBezierPath(ovalIn: sugarRect)
    let sugarGradient = NSGradient(colors: [
        warmLightColor, NSColor(calibratedRed: 0.83, green: 0.47, blue: 0.16, alpha: 1), warmColor,
    ])!
    sugarGradient.draw(in: sugar, relativeCenterPosition: NSPoint(x: 0.18, y: -0.18))

    NSColor(calibratedWhite: 1, alpha: 0.16).setStroke()
    sugar.lineWidth = max(1, canvas.width * 0.0022)
    sugar.stroke()
}

private func drawCoconutFlakes(in orbRect: CGRect, canvas: CGSize) {
    for flake in coconutFlakes {
        let flakeRect = CGRect(
            x: orbRect.minX + orbRect.width * flake.0,
            y: orbRect.minY + orbRect.height * flake.1,
            width: orbRect.width * flake.2,
            height: orbRect.height * flake.3
        )

        let shadowRect = flakeRect.offsetBy(dx: orbRect.width * 0.008, dy: -orbRect.height * 0.008)
        let shadow = NSBezierPath(ovalIn: shadowRect)
        coconutShadowColor.setFill()
        shadow.fill()

        NSGraphicsContext.saveGraphicsState()
        if let cgContext = NSGraphicsContext.current?.cgContext {
            cgContext.translateBy(x: flakeRect.midX, y: flakeRect.midY)
            cgContext.rotate(by: flake.4 * .pi / 180)
            cgContext.translateBy(x: -flakeRect.midX, y: -flakeRect.midY)
        }

        let flakePath = NSBezierPath(ovalIn: flakeRect)
        coconutColor.setFill()
        flakePath.fill()
        NSColor(calibratedWhite: 1, alpha: 0.26).setStroke()
        flakePath.lineWidth = max(0.4, canvas.width * 0.0009)
        flakePath.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }
}

private func renderPNG(canvas: CGSize, opaque: Bool = false, draw: (CGRect) throws -> Void) throws
    -> Data
{
    let pixelsWide = Int(canvas.width)
    let pixelsHigh = Int(canvas.height)

    guard
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelsWide,
            pixelsHigh: pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else {
        throw NSError(
            domain: "BrandAssetGenerator",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Unable to allocate bitmap for \(pixelsWide)x\(pixelsHigh)"
            ]
        )
    }

    rep.size = canvas

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        throw NSError(
            domain: "BrandAssetGenerator",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap graphics context"]
        )
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.shouldAntialias = true
    context.imageInterpolation = .high
    context.cgContext.setAllowsAntialiasing(true)
    context.cgContext.setShouldAntialias(true)

    if opaque {
        backgroundColor.setFill()
        CGRect(origin: .zero, size: canvas).fill()
    }

    try draw(CGRect(origin: .zero, size: canvas))
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(
            domain: "BrandAssetGenerator",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"]
        )
    }

    return png
}

private func writeJSON(_ object: [String: Any], to url: URL) throws {
    let data = try JSONSerialization.data(
        withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url, options: .atomic)
}

private func drawText(_ string: String, in rect: CGRect, font: NSFont, color: NSColor) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .left
    paragraph.lineBreakMode = .byClipping

    let attributed = NSAttributedString(
        string: string,
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
