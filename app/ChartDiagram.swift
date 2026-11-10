import SwiftUI

enum ChartStyle: String, CaseIterable, Identifiable {
    case south = "South Indian"
    case north = "North Indian"
    var id: String { rawValue }
}

/// One chart wheel: the grahas' labels by sign, drawn in the South (signs fixed) or North (houses fixed) form.
struct ChartDiagram: View {
    var style: ChartStyle
    var title: String
    var ascSign: Int
    /// labels by sign, 0 = Mesha
    var bySign: [Int: [String]]

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            switch style {
            case .south: drawSouth(&context, origin, side)
            case .north: drawNorth(&context, origin, side)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("\(title) chart, \(style.rawValue) style")
    }

    private var line: GraphicsContext.Shading { .color(.primary.opacity(0.55)) }

    private func lines(_ labels: [String], perRow: Int) -> String {
        stride(from: 0, to: labels.count, by: perRow)
            .map { labels[$0..<min($0 + perRow, labels.count)].joined(separator: " ") }
            .joined(separator: "\n")
    }

    // Signs keep their cells: Meena top-left, then clockwise.
    private static let southCells: [(row: Int, col: Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (2, 3), (3, 3), (3, 2), (3, 1), (3, 0), (2, 0), (1, 0), (0, 0)]

    private func drawSouth(_ context: inout GraphicsContext, _ origin: CGPoint, _ side: CGFloat) {
        let cell = side / 4
        for sign in 0..<12 {
            let at = Self.southCells[sign]
            let rect = CGRect(x: origin.x + CGFloat(at.col) * cell, y: origin.y + CGFloat(at.row) * cell, width: cell, height: cell)
            context.stroke(Path(rect), with: line, lineWidth: 1)
            context.draw(Text(Names.signCodes[sign]).font(.system(size: side * 0.028)).foregroundStyle(.secondary),
                         at: CGPoint(x: rect.maxX - side * 0.012, y: rect.minY + side * 0.01), anchor: .topTrailing)
            if sign == ascSign {
                var mark = Path()
                mark.move(to: CGPoint(x: rect.minX, y: rect.minY + cell * 0.3))
                mark.addLine(to: CGPoint(x: rect.minX + cell * 0.3, y: rect.minY))
                context.stroke(mark, with: .color(.accentColor), lineWidth: 2)
            }
            let text = Text(lines(bySign[sign] ?? [], perRow: 2)).font(.system(size: side * 0.04, weight: .medium))
            context.draw(text, at: CGPoint(x: rect.midX, y: rect.midY + side * 0.01), anchor: .center)
        }
        context.draw(Text(title).font(.system(size: side * 0.05, weight: .semibold)), at: CGPoint(x: origin.x + side / 2, y: origin.y + side / 2), anchor: .center)
    }

    // Houses keep their places: the first is the upper diamond, the rest follow counter-clockwise.
    private static let northCentres: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.25), CGPoint(x: 0.25, y: 0.09), CGPoint(x: 0.09, y: 0.25), CGPoint(x: 0.25, y: 0.5),
        CGPoint(x: 0.09, y: 0.75), CGPoint(x: 0.25, y: 0.91), CGPoint(x: 0.5, y: 0.75), CGPoint(x: 0.75, y: 0.91),
        CGPoint(x: 0.91, y: 0.75), CGPoint(x: 0.75, y: 0.5), CGPoint(x: 0.91, y: 0.25), CGPoint(x: 0.75, y: 0.09),
    ]
    private static let northInner: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5),
        CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.75),
        CGPoint(x: 0.75, y: 0.75), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.25), CGPoint(x: 0.75, y: 0.25),
    ]

    private func drawNorth(_ context: inout GraphicsContext, _ origin: CGPoint, _ side: CGFloat) {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: origin.x + x * side, y: origin.y + y * side) }
        var frame = Path(CGRect(x: origin.x, y: origin.y, width: side, height: side))
        frame.move(to: point(0, 0)); frame.addLine(to: point(1, 1))
        frame.move(to: point(1, 0)); frame.addLine(to: point(0, 1))
        frame.move(to: point(0.5, 0)); frame.addLine(to: point(1, 0.5)); frame.addLine(to: point(0.5, 1)); frame.addLine(to: point(0, 0.5)); frame.closeSubpath()
        context.stroke(frame, with: line, lineWidth: 1)
        for house in 0..<12 {
            let sign = (ascSign + house) % 12
            let centre = Self.northCentres[house], inner = Self.northInner[house]
            let number = point(centre.x + (inner.x - centre.x) * 0.72, centre.y + (inner.y - centre.y) * 0.72)
            context.draw(Text("\(sign + 1)").font(.system(size: side * 0.03)).foregroundStyle(.secondary), at: number, anchor: .center)
            // the four diamonds are roomy; the triangles on the left and right edges are narrow and tall,
            // so their grahas stack one to a line; those on the top and bottom edges are wide and shallow
            let diamond = house % 3 == 0
            let sideTriangle = [2, 4, 8, 10].contains(house)
            let labels = bySign[sign] ?? []
            let text = Text(lines(labels, perRow: diamond ? 3 : sideTriangle ? 1 : 2))
                .font(.system(size: side * (diamond ? 0.04 : labels.count > 4 ? 0.026 : 0.032), weight: .medium))
            let x = sideTriangle ? (centre.x < 0.5 ? 0.012 : 0.988) : centre.x
            context.draw(text, at: point(x, centre.y), anchor: sideTriangle ? (centre.x < 0.5 ? .leading : .trailing) : .center)
        }
        context.draw(Text(title).font(.system(size: side * 0.03, weight: .semibold)).foregroundStyle(.secondary), at: point(0.5, 0.035), anchor: .center)
    }
}
