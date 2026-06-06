#!/usr/bin/env swift
import AppKit

// Menu-bar (status item) icon generator for Tmux Kit.
// A monochrome PANE-SPLIT glyph matching the app icon: a filled active pane on
// the left + two half-tone panes on the right. Emitted as a TEMPLATE image so
// macOS tints it black/white to fit the bar; the alpha tiers (1.0 vs ~0.45)
// survive tinting, so the "active vs inactive" reading holds in monochrome.

// Draw the three panes into the current context, using `base` at full and half
// alpha. `box` is the glyph's bounding rect (y-up).
func drawPanes(in box: CGRect, base: NSColor) {
    let W = box.width, H = box.height
    let g = W * 0.11
    let r = W * 0.10
    let leftW = (W - g) * 0.46
    let left = CGRect(x: box.minX, y: box.minY, width: leftW, height: H)
    let rightX = box.minX + leftW + g
    let rightW = W - leftW - g
    let topH = (H - g) * 0.52
    let rTop = CGRect(x: rightX, y: box.minY + H - topH, width: rightW, height: topH)
    let rBot = CGRect(x: rightX, y: box.minY, width: rightW, height: H - topH - g)

    base.withAlphaComponent(1.0).setFill()
    NSBezierPath(roundedRect: left, xRadius: r, yRadius: r).fill()
    base.withAlphaComponent(0.45).setFill()
    NSBezierPath(roundedRect: rTop, xRadius: r * 0.8, yRadius: r * 0.8).fill()
    NSBezierPath(roundedRect: rBot, xRadius: r * 0.8, yRadius: r * 0.8).fill()
}

func glyphBox(_ px: Int, pad: CGFloat = 0.12) -> CGRect {
    let p = CGFloat(px) * pad
    return CGRect(x: p, y: p, width: CGFloat(px) - 2 * p, height: CGFloat(px) - 2 * p)
}

func newRep(_ w: Int, _ h: Int) -> NSBitmapImageRep {
    NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
}

func renderTemplate(_ px: Int) -> Data {
    let rep = newRep(px, px)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    drawPanes(in: glyphBox(px), base: .black)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath)
let setDir = root.appendingPathComponent("MacTmuxKit/Resources/Assets.xcassets/MenuBarIcon.imageset")
try? fm.createDirectory(at: setDir, withIntermediateDirectories: true)
try! renderTemplate(18).write(to: setDir.appendingPathComponent("menubar_18.png"))
try! renderTemplate(36).write(to: setDir.appendingPathComponent("menubar_36.png"))

let contents = """
{
  "images" : [
    {"idiom":"mac","scale":"1x","filename":"menubar_18.png"},
    {"idiom":"mac","scale":"2x","filename":"menubar_36.png"}
  ],
  "info" : {"author":"xcode","version":1},
  "properties" : {"template-rendering-intent":"template"}
}
"""
try! contents.write(to: setDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)

// Verification preview (not shipped): tinted on a light bar and a dark bar.
func preview() {
    let scale = 4, sizes = [16, 18, 22], pad = 24, gap = 30
    let stripH = 22 * scale + 2 * pad
    let W = pad * 2 + sizes.map { $0 * scale }.reduce(0, +) + gap * (sizes.count - 1)
    let H = stripH * 2
    let r = newRep(W, H)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: r)
    color(0.16, 0.16, 0.17).setFill()
    NSBezierPath(rect: CGRect(x: 0, y: 0, width: W, height: stripH)).fill()          // dark (bottom)
    color(0.93, 0.93, 0.94).setFill()
    NSBezierPath(rect: CGRect(x: 0, y: stripH, width: W, height: stripH)).fill()      // light (top)
    var x = pad
    for sz in sizes {
        let px = sz * scale
        drawPanes(in: glyphBox(px).offsetBy(dx: CGFloat(x), dy: CGFloat(stripH + pad)),
                  base: color(0.12, 0.12, 0.14))   // dark glyph on light bar
        drawPanes(in: glyphBox(px).offsetBy(dx: CGFloat(x), dy: CGFloat(pad)),
                  base: .white)                      // white glyph on dark bar
        x += px + gap
    }
    NSGraphicsContext.restoreGraphicsState()
    try! r.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "/tmp/menubar-preview.png"))
}
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: 1) }
preview()
print("Menu-bar icon set written to \(setDir.path); preview at /tmp/menubar-preview.png")
