#!/usr/bin/env swift
import AppKit

// Tmux Kit app icon generator.
// Design (taste-skill: single accent, no AI-purple, no pure black, bold at 16px):
// a dark slate squircle holding the classic tmux pane split — one full-height
// pane on the left, two stacked on the right, separated by dark "border" gaps.
// The left pane is the active one: a green-tinted fill, a green outline, and a
// small terminal cursor block (the app's Flexoki accent, matching Theme.accent).

func color(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: a)
}

let bgTop = color(0x21, 0x29, 0x38)      // lighter slate (top)
let bgBottom = color(0x0C, 0x10, 0x16)   // deep ink (bottom), not pure black
let accent = color(0x66, 0x80, 0x0B)            // Flexoki green = the app's accent (Theme.accent fallback)
let accentTint = color(0x66, 0x80, 0x0B, 0.16)  // active pane fill wash
let surface = color(0x46, 0x53, 0x67)           // neutral pane
let surfaceDim = color(0x37, 0x42, 0x53)         // quieter pane

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

    // Pane split: one full-height pane on the left (active), two stacked on the
    // right, separated by dark gaps that read as tmux pane borders.
    let content = rect.insetBy(dx: rect.width * 0.205, dy: rect.width * 0.205)
    let gap = content.width * 0.055
    let prad = content.width * 0.05
    let leftW = content.width * 0.50 - gap / 2

    let left = CGRect(x: content.minX, y: content.minY, width: leftW, height: content.height)
    let rx = left.maxX + gap
    let rw = content.maxX - rx
    let topH = content.height * 0.56 - gap / 2
    let rTop = CGRect(x: rx, y: content.maxY - topH, width: rw, height: topH)
    let rBot = CGRect(x: rx, y: content.minY, width: rw, height: content.height - topH - gap)

    surface.setFill()
    NSBezierPath(roundedRect: rTop, xRadius: prad, yRadius: prad).fill()
    surfaceDim.setFill()
    NSBezierPath(roundedRect: rBot, xRadius: prad, yRadius: prad).fill()

    // Active (left) pane: green-tinted fill + green outline + cursor block.
    accentTint.setFill()
    NSBezierPath(roundedRect: left, xRadius: prad, yRadius: prad).fill()
    let outline = NSBezierPath(roundedRect: left, xRadius: prad, yRadius: prad)
    outline.lineWidth = content.width * 0.020
    accent.setStroke()
    outline.stroke()

    let curW = content.width * 0.085
    let curH = content.width * 0.155
    let cursor = CGRect(
        x: left.minX + content.width * 0.085,
        y: left.maxY - curH - content.width * 0.085,
        width: curW, height: curH
    )
    accent.setFill()
    NSBezierPath(roundedRect: cursor, xRadius: curW * 0.18, yRadius: curW * 0.18).fill()

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
