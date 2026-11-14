import SwiftUI

/// The two zodiacs and the distance between them at this birth: the tropical zodiac begins at the March equinox,
/// the sidereal zodiac is fixed to the stars, and the ayanamsa is how far the equinox has slipped back.
struct ZodiacCard: View {
    let chart: Chart
    private static let short = ["Ar", "Ta", "Ge", "Cn", "Le", "Vi", "Li", "Sc", "Sg", "Cp", "Aq", "Pi"]

    private func place(_ lon: Double) -> String {
        let l = (lon.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360), sign = Int(l / 30), deg = l - Double(sign) * 30
        return String(format: "\(Names.signs[sign]) %d°%02d′", Int(deg), Int((deg - Double(Int(deg))) * 60))
    }
    private func sign(_ lon: Double) -> Int { Int(((lon.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)) / 30) }

    /// outer ring: the tropical signs from the equinox; inner ring: the sidereal signs, turned by the ayanamsa
    private var rings: some View {
        Canvas { context, size in
            let pen = context, centre = CGPoint(x: size.width / 2, y: size.height / 2), outer = min(size.width, size.height) / 2 - 6
            let point = { (lon: Double, r: CGFloat) in CGPoint(x: centre.x - r * CGFloat(cos(lon * .pi / 180)), y: centre.y + r * CGFloat(sin(lon * .pi / 180))) }
            let ring = { (r: CGFloat, offset: Double, colour: Color) in
                pen.stroke(Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: 2 * r, height: 2 * r)), with: .color(colour.opacity(0.6)), lineWidth: 1)
                pen.stroke(Path(ellipseIn: CGRect(x: centre.x - r + 24, y: centre.y - r + 24, width: 2 * r - 48, height: 2 * r - 48)), with: .color(colour.opacity(0.6)), lineWidth: 1)
                for i in 0..<12 {
                    let at = Double(i) * 30 + offset
                    pen.stroke(Path { $0.move(to: point(at, r)); $0.addLine(to: point(at, r - 24)) }, with: .color(colour.opacity(i == 0 ? 1 : 0.5)), lineWidth: i == 0 ? 2.5 : 1)
                    pen.draw(Text(Self.short[i]).font(.caption2).foregroundColor(colour), at: point(at + 15, r - 12))
                }
            }
            ring(outer, 0, .orange)
            ring(outer - 30, chart.ayanamsa, .teal)
            if let sun = chart.graha("Su") {
                let spot = point(sun.lon + chart.ayanamsa, outer - 66)
                pen.fill(Path(ellipseIn: CGRect(x: spot.x - 6, y: spot.y - 6, width: 12, height: 12)), with: .color(.yellow))
                pen.stroke(Path { $0.move(to: centre); $0.addLine(to: point(sun.lon + chart.ayanamsa, outer)) }, with: .color(.yellow.opacity(0.5)), lineWidth: 1)
            }
            pen.draw(Text("Earth").font(.caption2).foregroundColor(.secondary), at: centre)
        }
        .frame(width: 280, height: 280)
    }

    var body: some View {
        let ay = chart.ayanamsa, mode = Names.ayanamsas[chart.ayanamsa_mode] ?? chart.ayanamsa_mode
        let rows: [(String, String?, Double)] = [("Lagna", nil, chart.asc.lon)] + chart.grahas.map { (Names.lords[$0.id] ?? $0.id, $0.id, $0.lon) }
        let moved = rows.filter { sign($0.2) != sign($0.2 + ay) }.count, years = ay * 3600 / 50.29
        let sunTropical = ((chart.graha("Su")?.lon ?? 0) + ay).truncatingRemainder(dividingBy: 360)
        let season = ["between the March equinox and the June solstice", "between the June solstice and the September equinox", "between the September equinox and the December solstice", "between the December solstice and the March equinox"][min(3, Int(sunTropical / 90))]
        let widths: [CGFloat] = [78, 150, 150, 110]
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    rings
                    Text("Orange, outer: the tropical signs, begun at the March equinox. Teal, inner: the sidereal signs, fixed to the stars and used in Jyotish. The yellow dot is the Sun at birth.")
                        .font(.caption2).foregroundStyle(.secondary).frame(width: 280, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                }
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(String(format: "Ayanamsa at this birth: %d°%02d′ (\(mode))", Int(ay), Int((ay - Double(Int(ay))) * 60))).font(.headline)
                        Text("Ayanamsa, the moving portion, is the distance between the two zodiacs. The earth's axis turns slowly like a spinning top, so the March equinox slips back against the stars by about 50 seconds of arc a year, a full circle in about 26,000 years. \(chart.ayanamsa_mode == "raman" ? "This reckoning follows B.V. Raman." : "This reckoning fixes the zodiac by the star Chitra (Spica), set at the start of Tula.") The two zodiacs stood together about \(Int((years / 10).rounded()) * 10) years before this birth.")
                            .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        Text(String(format: "The seasons follow the earth's tilt of about 23.5°: the solstices are the turning points of light, the equinoxes the days of equal light. The Sun at this birth stood %.0f° past the March equinox, \(season).", sunTropical))
                            .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(width: widths.reduce(0, +), alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        SheetRow(graha: nil, cells: zip(["", "Sidereal (used here)", "Tropical", "Sign"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                        ForEach(rows, id: \.0) { row in
                            let same = sign(row.2) == sign(row.2 + ay)
                            SheetRow(graha: row.1, cells: [
                                SheetCell(text: row.0, width: widths[0], tint: row.1.map { Tint.graha($0) }),
                                SheetCell(text: place(row.2), width: widths[1], met: true),
                                SheetCell(text: place(row.2 + ay), width: widths[2]),
                                SheetCell(text: same ? "the same" : "one sign back", width: widths[3])])
                        }
                        Text("\(moved) of \(rows.count) points stand one sign earlier in the sidereal zodiac than in the tropical. The sidereal zodiac is the one observed against the stars; every other card reads it.")
                            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 6)
                    }
                }
            }
        }
    }
}
