import SwiftUI

enum ChartStyle: String, CaseIterable, Identifiable {
    case south = "South Indian"
    case north = "North Indian"
    var id: String { rawValue }
}

/// Screen colours, one per graha, that hold in light and dark.
enum Tint {
    static func graha(_ code: String) -> Color {
        switch code.prefix(2) {
        case "Su": return .orange
        case "Ma": return .red
        case "Me": return .green
        case "Ju": return .yellow
        case "Ve": return .pink
        case "Sa": return .blue
        case "Ra": return .gray
        case "Ke": return .brown
        default: return .primary
        }
    }
}

/// One label in a chart: a graha (or the lagna) and what to show for it.
struct ChartMark: Identifiable {
    /// the graha's code, or "As"
    var code: String
    var label: String
    /// a transit position, drawn lighter beside the birth positions
    var transit = false
    /// retrograde: the label is underlined
    var retro = false
    /// the sign a click on this mark picks, when it is not a graha (the lagna's own sign)
    var sign: Int? = nil
    var id: String { (transit ? "t-" : "") + code }
}

/// A chart every part of which can be pointed at: a graha's label picks the graha, a sign's field picks the sign.
struct ChartView: View {
    @EnvironmentObject var store: Store
    var style: ChartStyle
    var title: String
    var ascSign: Int
    /// marks by sign, 0 = Mesha
    var marks: [Int: [ChartMark]]
    /// signs the picked graha aspects: tinted
    var aspected: [Int] = []
    /// signs the graha in focus rules: tinted
    var owned: [Int] = []

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack(alignment: .topLeading) {
                if style == .south { south(side) } else { north(side) }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: shared pieces

    private func wash(_ sign: Int) -> Color {
        if store.pick == .sign(sign) { return Color.accentColor.opacity(0.22) }
        if store.hover == .sign(sign) { return Color.accentColor.opacity(0.09) }
        if aspected.contains(sign) { return Color.orange.opacity(0.16) }
        if owned.contains(sign) { return Color.green.opacity(0.14) }
        return Color.primary.opacity(0.0001)
    }

    private func label(_ mark: ChartMark, size: CGFloat) -> some View {
        let pick: Pick = mark.sign.map { .sign($0) } ?? (mark.code == "As" ? .sign(ascSign) : .graha(mark.code))
        let chosen = mark.sign == nil && store.pick?.graha == mark.code, near = mark.sign == nil && (store.hover?.graha == mark.code || store.glow.contains(mark.code))
        return Text(mark.label)
            .font(.system(size: size, weight: mark.transit ? .regular : .medium))
            .italic(mark.transit)
            .underline(mark.retro)
            .foregroundStyle(mark.code == "As" ? Color.accentColor : Tint.graha(mark.code).opacity(mark.transit ? 0.75 : 1))
            .padding(.horizontal, 3)
            .background(Capsule().fill(Color.accentColor.opacity(chosen ? 0.3 : near ? 0.14 : 0)))
            .contentShape(Rectangle())
            .onTapGesture { store.pick = pick }
            .onHover { inside in store.hover = inside ? pick : (store.hover == pick ? nil : store.hover) }
            .accessibilityLabel("\(mark.transit ? "transit " : "")\(mark.label)")
            .help(mark.code == "As" ? (Help.term("Lagna") ?? "") : mark.sign != nil ? "The arudha pada \(mark.code): the image a house casts" : (mark.transit ? "In the sky of the moment. " : "") + Help.graha(mark.code) + (mark.retro ? " Retrograde." : ""))
    }

    private func labels(_ sign: Int, perRow: Int, size: CGFloat) -> some View {
        let all = marks[sign] ?? []
        let rows = stride(from: 0, to: all.count, by: perRow).map { Array(all[$0..<min($0 + perRow, all.count)]) }
        return VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 1) { ForEach(rows[row]) { label($0, size: size) } }
            }
        }
        .fixedSize()
    }

    // MARK: South Indian: the signs keep their cells, Meena top-left, then clockwise

    private static let southCells: [(row: Int, col: Int)] = [(0, 1), (0, 2), (0, 3), (1, 3), (2, 3), (3, 3), (3, 2), (3, 1), (3, 0), (2, 0), (1, 0), (0, 0)]

    private func south(_ side: CGFloat) -> some View {
        let cell = side / 4
        return ZStack(alignment: .topLeading) {
            ForEach(0..<12, id: \.self) { sign in
                let at = Self.southCells[sign]
                ZStack {
                    Rectangle().fill(wash(sign)).contentShape(Rectangle())
                        .onTapGesture { store.pick = .sign(sign) }
                        .onHover { inside in store.hover = inside ? .sign(sign) : (store.hover == .sign(sign) ? nil : store.hover) }
                    Rectangle().stroke(Color.primary.opacity(0.45), lineWidth: 0.8).allowsHitTesting(false)
                    Text(Names.signCodes[sign]).font(.system(size: max(8, side * 0.028))).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(3).allowsHitTesting(false)
                    if sign == ascSign {
                        Path { p in p.move(to: CGPoint(x: 0, y: cell * 0.3)); p.addLine(to: CGPoint(x: cell * 0.3, y: 0)) }
                            .stroke(Color.accentColor, lineWidth: 2).allowsHitTesting(false)
                    }
                    labels(sign, perRow: 2, size: max(10, side * 0.04)).padding(.top, side * 0.02)
                }
                .frame(width: cell, height: cell)
                .offset(x: CGFloat(at.col) * cell, y: CGFloat(at.row) * cell)
            }
            Text(title).font(.system(size: max(10, side * 0.045), weight: .semibold)).foregroundStyle(.secondary)
                .frame(width: side, height: side).allowsHitTesting(false)
        }
    }

    // MARK: North Indian: the houses keep their places, the first in the upper diamond, the rest counter-clockwise

    private static let northShapes: [[CGPoint]] = [
        [CGPoint(x: 0.5, y: 0), CGPoint(x: 0.75, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.25, y: 0.25)],
        [CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0), CGPoint(x: 0.25, y: 0.25)],
        [CGPoint(x: 0, y: 0), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0, y: 0.5)],
        [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0, y: 0.5)],
        [CGPoint(x: 0, y: 0.5), CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0, y: 1)],
        [CGPoint(x: 0, y: 1), CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.5, y: 1)],
        [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.75), CGPoint(x: 0.5, y: 1), CGPoint(x: 0.25, y: 0.75)],
        [CGPoint(x: 0.5, y: 1), CGPoint(x: 0.75, y: 0.75), CGPoint(x: 1, y: 1)],
        [CGPoint(x: 1, y: 1), CGPoint(x: 0.75, y: 0.75), CGPoint(x: 1, y: 0.5)],
        [CGPoint(x: 0.75, y: 0.25), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.75, y: 0.75), CGPoint(x: 0.5, y: 0.5)],
        [CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.75, y: 0.25)],
        [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 0.75, y: 0.25)],
    ]
    private static let northCentres: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.25), CGPoint(x: 0.25, y: 0.1), CGPoint(x: 0.105, y: 0.25), CGPoint(x: 0.25, y: 0.5),
        CGPoint(x: 0.105, y: 0.75), CGPoint(x: 0.25, y: 0.9), CGPoint(x: 0.5, y: 0.75), CGPoint(x: 0.75, y: 0.9),
        CGPoint(x: 0.895, y: 0.75), CGPoint(x: 0.75, y: 0.5), CGPoint(x: 0.895, y: 0.25), CGPoint(x: 0.75, y: 0.1),
    ]
    private static let northCorners: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5),
        CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.75),
        CGPoint(x: 0.75, y: 0.75), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.25), CGPoint(x: 0.75, y: 0.25),
    ]

    private func northShape(_ house: Int, _ side: CGFloat) -> Path {
        Path { p in
            let points = Self.northShapes[house].map { CGPoint(x: $0.x * side, y: $0.y * side) }
            p.move(to: points[0]); points.dropFirst().forEach { p.addLine(to: $0) }; p.closeSubpath()
        }
    }

    private func north(_ side: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<12, id: \.self) { house in
                let sign = (ascSign + house) % 12, shape = northShape(house, side)
                shape.fill(wash(sign)).contentShape(shape)
                    .onTapGesture { store.pick = .sign(sign) }
                    .onHover { inside in store.hover = inside ? .sign(sign) : (store.hover == .sign(sign) ? nil : store.hover) }
                shape.stroke(Color.primary.opacity(0.45), lineWidth: 0.8).allowsHitTesting(false)
            }
            ForEach(0..<12, id: \.self) { house in
                let sign = (ascSign + house) % 12, centre = Self.northCentres[house], corner = Self.northCorners[house]
                Text("\(sign + 1)").font(.system(size: max(8, side * 0.028))).foregroundStyle(.secondary).allowsHitTesting(false)
                    .position(x: (centre.x + (corner.x - centre.x) * 0.76) * side, y: (centre.y + (corner.y - centre.y) * 0.76) * side)
                labels(sign, perRow: house % 3 == 0 ? 3 : [2, 4, 8, 10].contains(house) ? 1 : 2, size: max(10, side * (house % 3 == 0 ? 0.04 : 0.033)))
                    .position(x: centre.x * side, y: centre.y * side)
            }
            Text(title).font(.system(size: max(9, side * 0.03), weight: .semibold)).foregroundStyle(.secondary)
                .position(x: side / 2, y: side * 0.035).allowsHitTesting(false)
        }
    }
}
