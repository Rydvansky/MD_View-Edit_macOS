import AppKit
import Foundation

let outputURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "dmg-background.png")
let size = NSSize(width: 760, height: 430)
let image = NSImage(size: size)

image.lockFocus()

NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()

let accent = NSColor(calibratedRed: 0.08, green: 0.35, blue: 0.72, alpha: 1)
let textColor = NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.16, alpha: 1)
let mutedColor = NSColor(calibratedRed: 0.38, green: 0.42, blue: 0.48, alpha: 1)

let title = "Install MD_View-Edit_macOS"
let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 28, weight: .semibold),
    .foregroundColor: textColor
]
title.draw(at: NSPoint(x: 36, y: 362), withAttributes: titleAttributes)

let subtitle = "Drag the app icon into the Applications folder"
let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 16, weight: .regular),
    .foregroundColor: mutedColor
]
subtitle.draw(at: NSPoint(x: 38, y: 335), withAttributes: subtitleAttributes)

let arrow = NSBezierPath()
arrow.lineWidth = 8
arrow.lineCapStyle = .round
arrow.move(to: NSPoint(x: 245, y: 215))
arrow.curve(to: NSPoint(x: 515, y: 215), controlPoint1: NSPoint(x: 330, y: 270), controlPoint2: NSPoint(x: 430, y: 270))
accent.setStroke()
arrow.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: NSPoint(x: 515, y: 215))
arrowHead.line(to: NSPoint(x: 480, y: 238))
arrowHead.line(to: NSPoint(x: 489, y: 215))
arrowHead.line(to: NSPoint(x: 480, y: 192))
arrowHead.close()
accent.setFill()
arrowHead.fill()

let appLabel = "1. Open"
let applicationsLabel = "2. Drop here"
let labelAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
    .foregroundColor: textColor
]
appLabel.draw(at: NSPoint(x: 107, y: 72), withAttributes: labelAttributes)
applicationsLabel.draw(at: NSPoint(x: 565, y: 72), withAttributes: labelAttributes)

let footer = "If macOS warns about an unidentified developer, allow the app in Privacy & Security."
let footerAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12, weight: .regular),
    .foregroundColor: mutedColor
]
footer.draw(at: NSPoint(x: 36, y: 24), withAttributes: footerAttributes)

image.unlockFocus()

if let tiff = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiff),
   let png = bitmap.representation(using: .png, properties: [:]) {
    try png.write(to: outputURL)
} else {
    fputs("Could not create DMG background image\n", stderr)
    exit(1)
}
