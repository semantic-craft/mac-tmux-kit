#!/usr/bin/env swift
import AppKit

// Tmux Kit app icon generator.
// Design (taste-skill: single accent, no AI-purple, no pure black, bold at 16px):
// a dark slate squircle holding three parallel rounded "thread" bars of varying
// length (= parallel sessions), each led by a status dot; one thread is system
// green (the active/attached one, matching the app's UI), capped by a small
// terminal cursor block.

func color(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: a)
}

let bgTop = color(0x21, 0x29, 0x38)      // lighter slate (top)
let bgBottom = color(0x0C, 0x10, 0x16)   // deep ink (bottom), not pure black
let accent = color(0x30, 0xD1, 0x58)     // system green = active thread
let barLight = color(0xCE, 0xD5, 0xDF)   // primary threads
let barDim = color(0x8C, 0x96, 0xA6)     // a quieter third thread

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    // Squircle-ish content square with macOS-style transparent margin.
    let inset = s * 0.0977
    let rect = CGRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let radius = rect.width * 0.2245
    let bg = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    NSGradient(colors: [bgBottom, bgTop])?.draw(in: bg, angle: 90)

    // Subtle top edge highlight for depth.
    bg.lineWidth = max(1, s * 0.004)
    color(255, 255, 255, 0.06).setStroke()
    bg.stroke()

    // Thread rows.
    let pad = rect.width * 0.205
    let dotR = rect.width * 0.043
    let barH = rect.width * 0.072
    let gap = rect.height * 0.105
    let barStartX = rect.minX + pad + dotR * 2 + rect.width * 0.05
    let maxBarW = rect.maxX - pad - barStartX

    let widths: [CGFloat] = [0.60, 0.86, 0.46]   // varying lengths
    let dotColors = [barLight, accent, barDim]
    let barColors = [barLight, accent, barDim]
    let accentRow = 1

    let groupH = barH * 3 + gap * 2
    let topCenterY = rect.midY + groupH / 2 - barH / 2

    for i in 0..<3 {
        let cy = topCenterY - CGFloat(i) * (barH + gap)

        // Status dot.
        let dotRect = CGRect(x: rect.minX + pad, y: cy - dotR, width: dotR * 2, height: dotR * 2)
        dotColors[i].setFill()
        NSBezierPath(ovalIn: dotRect).fill()

        // Thread bar (capsule).
        let w = widths[i] * maxBarW
        let barRect = CGRect(x: barStartX, y: cy - barH / 2, width: w, height: barH)
        barColors[i].setFill()
        NSBezierPath(roundedRect: barRect, xRadius: barH / 2, yRadius: barH / 2).fill()

        // Terminal cursor block at the end of the accent thread.
        if i == accentRow {
            let cur = barH * 0.92
            let curRect = CGRect(x: barRect.maxX + rect.width * 0.03,
                                 y: cy - cur / 2, width: cur, height: cur)
            accent.setFill()
            NSBezierPath(roundedRect: curRect, xRadius: cur * 0.22, yRadius: cur * 0.22).fill()
        }
    }

    return rep.representation(using: .png, properties: [:])!
}

// Output to the asset catalog.
let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath)
let setDir = root.appendingPathComponent("MacTmuxKit/Resources/Assets.xcassets/AppIcon.appiconset")
try? fm.createDirectory(at: setDir, withIntermediateDirectories: true)
try? fm.createDirectory(
    at: root.appendingPathComponent("MacTmuxKit/Resources/Assets.xcassets"),
    withIntermediateDirectories: true
)

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for px in sizes {
    let data = render(px)
    try! data.write(to: setDir.appendingPathComponent("icon_\(px).png"))
}

let contents = """
{
  "images" : [
    {"idiom":"mac","scale":"1x","size":"16x16","filename":"icon_16.png"},
    {"idiom":"mac","scale":"2x","size":"16x16","filename":"icon_32.png"},
    {"idiom":"mac","scale":"1x","size":"32x32","filename":"icon_32.png"},
    {"idiom":"mac","scale":"2x","size":"32x32","filename":"icon_64.png"},
    {"idiom":"mac","scale":"1x","size":"128x128","filename":"icon_128.png"},
    {"idiom":"mac","scale":"2x","size":"128x128","filename":"icon_256.png"},
    {"idiom":"mac","scale":"1x","size":"256x256","filename":"icon_256.png"},
    {"idiom":"mac","scale":"2x","size":"256x256","filename":"icon_512.png"},
    {"idiom":"mac","scale":"1x","size":"512x512","filename":"icon_512.png"},
    {"idiom":"mac","scale":"2x","size":"512x512","filename":"icon_1024.png"}
  ],
  "info" : {"author":"xcode","version":1}
}
"""
try! contents.write(to: setDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
let catRoot = root.appendingPathComponent("MacTmuxKit/Resources/Assets.xcassets/Contents.json")
try! "{\n  \"info\" : {\"author\":\"xcode\",\"version\":1}\n}".write(to: catRoot, atomically: true, encoding: .utf8)

print("Icon set written to \(setDir.path)")
