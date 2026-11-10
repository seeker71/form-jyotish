// Draw the app icon: a North Indian chart in gold on a night sky, the lagna's diamond lit, one star rising.
//
//   swift tools/make-icon.swift art/icon-1024.png
import AppKit

let size: CGFloat = 1024
let space = CGColorSpaceCreateDeviceRGB()
let context = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(red: r, green: g, blue: b, alpha: a) }

// the rounded tile macOS icons stand on, with its margin
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
context.saveGState()
context.addPath(shape); context.clip()
let sky = CGGradient(colorsSpace: space, colors: [color(0.16, 0.07, 0.30), color(0.05, 0.04, 0.16), color(0.02, 0.02, 0.08)] as CFArray, locations: [0, 0.55, 1])!
context.drawLinearGradient(sky, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
// a warm glow low in the east, where the lagna rises
let dawn = CGGradient(colorsSpace: space, colors: [color(0.95, 0.45, 0.10, 0.55), color(0.95, 0.45, 0.10, 0)] as CFArray, locations: [0, 1])!
context.drawRadialGradient(dawn, startCenter: CGPoint(x: 512, y: 250), startRadius: 0, endCenter: CGPoint(x: 512, y: 250), endRadius: 520, options: [])
context.restoreGState()

// the chart: a square, its diagonals, and the diamond that joins the middles of its sides
let chart = tile.insetBy(dx: 120, dy: 120)
let (l, r, b, t, cx, cy) = (chart.minX, chart.maxX, chart.minY, chart.maxY, chart.midX, chart.midY)
// the first house, the upper diamond, lit
context.saveGState()
context.move(to: CGPoint(x: cx, y: t)); context.addLine(to: CGPoint(x: (cx + r) / 2, y: (cy + t) / 2)); context.addLine(to: CGPoint(x: cx, y: cy)); context.addLine(to: CGPoint(x: (cx + l) / 2, y: (cy + t) / 2)); context.closePath()
context.setFillColor(color(1.0, 0.78, 0.30, 0.22)); context.fillPath()
context.restoreGState()
let gold = color(1.0, 0.80, 0.36)
context.setStrokeColor(gold); context.setLineWidth(22); context.setLineJoin(.round); context.setLineCap(.round)
context.setShadow(offset: .zero, blur: 26, color: color(1.0, 0.70, 0.20, 0.8))
context.stroke(chart)
context.move(to: CGPoint(x: l, y: b)); context.addLine(to: CGPoint(x: r, y: t))
context.move(to: CGPoint(x: l, y: t)); context.addLine(to: CGPoint(x: r, y: b))
context.move(to: CGPoint(x: cx, y: t)); context.addLine(to: CGPoint(x: r, y: cy)); context.addLine(to: CGPoint(x: cx, y: b)); context.addLine(to: CGPoint(x: l, y: cy)); context.closePath()
context.strokePath()
// the star in the first house: four long rays and four short
let star = CGPoint(x: cx, y: (cy + t) / 2 + 6)
context.setShadow(offset: .zero, blur: 40, color: color(1, 1, 0.85, 1))
context.setFillColor(color(1, 0.98, 0.90))
let path = CGMutablePath()
for i in 0..<16 {
    let angle = CGFloat(i) * .pi / 8 + .pi / 2
    let reach: CGFloat = i % 2 == 1 ? 13 : (i % 4 == 0 ? 74 : 34)
    let point = CGPoint(x: star.x + cos(angle) * reach, y: star.y + sin(angle) * reach)
    if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
}
path.closeSubpath()
context.addPath(path); context.fillPath()

let image = NSBitmapImageRep(cgImage: context.makeImage()!)
try! image.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
