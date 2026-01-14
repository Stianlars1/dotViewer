#!/usr/bin/env swift
// DMG Background Generator for dotViewer
// Usage: swift generate-dmg-background.swift

import Cocoa

let width: CGFloat = 660
let height: CGFloat = 400

// Create bitmap context
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: Int(width),
    height: Int(height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create context")
    exit(1)
}

// Draw gradient background (purple to blue matching app icon)
let colors = [
    CGColor(red: 0.55, green: 0.36, blue: 0.85, alpha: 1.0),  // Purple (top)
    CGColor(red: 0.40, green: 0.50, blue: 0.92, alpha: 1.0)   // Blue (bottom)
]
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1])!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: height),
    end: CGPoint(x: 0, y: 0),
    options: []
)

// Draw "dotViewer" title at top (white text on dark background)
let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 36, weight: .bold),
    .foregroundColor: NSColor.white
]
let title = NSAttributedString(string: "dotViewer", attributes: titleAttributes)
let titleSize = title.size()
let titlePoint = NSPoint(x: (width - titleSize.width) / 2, y: height - 60)

// Create NSGraphicsContext for text drawing
NSGraphicsContext.saveGraphicsState()
let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.current = nsContext
title.draw(at: titlePoint)

// Draw subtitle
let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .regular),
    .foregroundColor: NSColor(white: 1.0, alpha: 0.8)
]
let subtitle = NSAttributedString(string: "Quick Look for Source Code & Dotfiles", attributes: subtitleAttributes)
let subtitleSize = subtitle.size()
let subtitlePoint = NSPoint(x: (width - subtitleSize.width) / 2, y: height - 90)
subtitle.draw(at: subtitlePoint)

// Draw instruction text at bottom
let instructionAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
    .foregroundColor: NSColor(white: 1.0, alpha: 0.9)
]
let instruction = NSAttributedString(string: "Drag to Applications to install", attributes: instructionAttributes)
let instructionSize = instruction.size()
let instructionPoint = NSPoint(x: (width - instructionSize.width) / 2, y: 50)
instruction.draw(at: instructionPoint)

// Draw arrow (simple curved line from app position to Applications position)
// App icon at x=150, Applications at x=500, both at y=200
context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5))
context.setLineWidth(2)
context.setLineCap(.round)

// Draw dashed arrow
let dashPattern: [CGFloat] = [6, 4]
context.setLineDash(phase: 0, lengths: dashPattern)

context.move(to: CGPoint(x: 220, y: 200))
context.addQuadCurve(to: CGPoint(x: 440, y: 200), control: CGPoint(x: 330, y: 140))
context.strokePath()

// Draw arrowhead
context.setLineDash(phase: 0, lengths: [])
context.move(to: CGPoint(x: 430, y: 210))
context.addLine(to: CGPoint(x: 445, y: 200))
context.addLine(to: CGPoint(x: 430, y: 190))
context.strokePath()

NSGraphicsContext.restoreGraphicsState()

// Create image and save
guard let cgImage = context.makeImage() else {
    print("Failed to create image")
    exit(1)
}

let bitmap = NSBitmapImageRep(cgImage: cgImage)
guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to create PNG data")
    exit(1)
}

// Get script directory and write to installer-assets
let scriptPath = CommandLine.arguments[0]
let scriptURL = URL(fileURLWithPath: scriptPath)
let projectDir = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let outputPath = projectDir.appendingPathComponent("installer-assets/dmg-background.png")

do {
    try pngData.write(to: outputPath)
    print("DMG background created: \(outputPath.path)")
} catch {
    // Try current directory fallback
    let fallbackPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("installer-assets/dmg-background.png")
    do {
        try pngData.write(to: fallbackPath)
        print("DMG background created: \(fallbackPath.path)")
    } catch {
        print("Failed to write file: \(error)")
        exit(1)
    }
}
