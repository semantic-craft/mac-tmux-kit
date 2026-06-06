#!/usr/bin/env swift
import AppKit

// Tmux Kit app icon generator.
// Concept (chosen from browser-rendered candidates): the tmux PANE SPLIT — one
// tall active pane on the left (violet, glowing, with a cursor block) and two
// stacked "glass" panes on the right. This says "multiplexer / session manager"
// and is deliberately NOT a ghost or a prompt, so it reads distinctly from
// Ghostty in the Dock. Violet pairs with Ghostty's palette without imitating it.
// Design space is 1024px; geometry scales by `u = s/1024`. Coordinates are y-up.

func color(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: a)
}
func hex(_ v: Int, _ a: CGFloat = 1) -> NSColor {
    color((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF, a)
}

let bgTop = hex(0x232C3C)       // lighter slate (top)
let bgBottom = hex(0x0B0F15)    // deep ink (bottom), not pure black
let violet = hex(0x8F86F7)      // active pane accent — pairs with Ghostty
let violetBright = hex(0xA89DFF) // cursor block

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let u = s / 1024
    func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
        NSBezierPath(roundedRect: CGRect(x: x * u, y: y * u, width: w * u, height: h * u),
                     xRadius: r * u, yRadius: r * u)
    }

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
    bg.lineWidth = max(1, s * 0.004)
    color(255, 255, 255, 0.06).setStroke()
    bg.stroke()

    // Right column: two stacked "glass" panes (y-up: upper first).
    func glass(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, fill: CGFloat, stroke: CGFloat) {
        let p = rrect(x, y, w, h, 26)
        color(255, 255, 255, fill).setFill(); p.fill()
        p.lineWidth = 2.4 * u; color(255, 255, 255, stroke).setStroke(); p.stroke()
    }
    glass(560, 536, 232, 188, fill: 0.09, stroke: 0.10)  // upper
    glass(560, 300, 232, 188, fill: 0.05, stroke: 0.08)  // lower

    // Left column: the active pane, with a soft violet glow.
    let active = rrect(232, 300, 280, 424, 30)
    NSGraphicsContext.saveGraphicsState()
    let glow = NSShadow()
    glow.shadowColor = violet.withAlphaComponent(0.55)
    glow.shadowBlurRadius = 30 * u
    glow.shadowOffset = .zero
    glow.set()
    active.lineWidth = 7 * u
    violet.setStroke()
    active.stroke()
    NSGraphicsContext.restoreGraphicsState()
    violet.withAlphaComponent(0.20).setFill()
    active.fill()
    active.lineWidth = 7 * u
    violet.setStroke()
    active.stroke()

    // Cursor block, top-left of the active pane.
    violetBright.setFill()
    rrect(278, 604, 46, 76, 10).fill()

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
