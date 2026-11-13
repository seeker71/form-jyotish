import SwiftUI

/// What the sky showed at the birth, drawn from the chart's own positions: the Moon's light, whether the birth
/// fell on an eclipse, and which of the five true planets are retrograde, combust or at war.
struct StrengthSky: View {
    let chart: Chart

    private func name(_ code: String) -> String { Names.lords[code] ?? code }
    private var five: [Graha] { chart.grahas.filter { Lore.five.contains($0.id) } }

    // MARK: the Moon

    /// the Moon's round from the Sun: new at the left, waxing along the bottom to full at the right, waning back
    /// along the top; the zones of new, dark, bright and full are tinted
    private var dial: some View {
        Canvas { context, size in
            let pen = context
            let centre = CGPoint(x: size.width / 2, y: size.height / 2), radius = min(size.width, size.height) / 2 - 16
            let point = { (e: Double, r: CGFloat) in CGPoint(x: centre.x - r * CGFloat(cos(e * .pi / 180)), y: centre.y + r * CGFloat(sin(e * .pi / 180))) }
            let arc = { (from: Double, to: Double, colour: Color) in
                var path = Path()
                for (i, e) in stride(from: from, through: to, by: 2).enumerated() { if i == 0 { path.move(to: point(e, radius)) } else { path.addLine(to: point(e, radius)) } }
                pen.stroke(path, with: .color(colour), lineWidth: 9)
            }
            arc(-30, 30, .orange.opacity(0.85)); arc(30, 72, .orange.opacity(0.4)); arc(288, 330, .orange.opacity(0.4))
            arc(72, 150, .green.opacity(0.35)); arc(210, 288, .green.opacity(0.35)); arc(150, 210, .green.opacity(0.85))
            let sun = point(0, radius)
            context.fill(Path(ellipseIn: CGRect(x: sun.x - 7, y: sun.y - 7, width: 14, height: 14)), with: .color(.yellow))
            let moon = point(chart.elongation, radius)
            context.fill(Path(ellipseIn: CGRect(x: moon.x - 8, y: moon.y - 8, width: 16, height: 16)), with: .color(.white))
            context.stroke(Path(ellipseIn: CGRect(x: moon.x - 8, y: moon.y - 8, width: 16, height: 16)), with: .color(.black.opacity(0.6)), lineWidth: 1.5)
            // the Moon's face in the middle: lit on the right while waxing, on the left while waning
            let r: CGFloat = 26, face = CGRect(x: centre.x - r, y: centre.y - r, width: 2 * r, height: 2 * r), lit = Color(white: 0.93), shade = Color(white: 0.28)
            context.fill(Path(ellipseIn: face), with: .color(shade))
            var half = context
            half.clip(to: Path(CGRect(x: chart.moonWaxing ? centre.x : centre.x - r, y: centre.y - r, width: r, height: 2 * r)))
            half.fill(Path(ellipseIn: face), with: .color(lit))
            let bulge = r * CGFloat(abs(cos(chart.elongation * .pi / 180)))
            context.fill(Path(ellipseIn: CGRect(x: centre.x - bulge, y: centre.y - r, width: 2 * bulge, height: 2 * r)), with: .color(chart.sunGap < 90 ? shade : lit))
            context.stroke(Path(ellipseIn: face), with: .color(.secondary), lineWidth: 0.8)
            let label = { (words: String, e: Double) in pen.draw(Text(words).font(.caption2).foregroundColor(.secondary), at: point(e, radius + 11)) }
            label("waxing", 90); label("waning", 270)
        }
        .frame(width: 190, height: 190)
        .overlay(alignment: .leading) { Text("new").font(.caption2).foregroundStyle(.secondary).offset(x: -14) }
        .overlay(alignment: .trailing) { Text("full").font(.caption2).foregroundStyle(.secondary).offset(x: 12) }
        .padding(.horizontal, 16)
    }

    private var moonWords: [String] {
        let word = chart.moonWord, waxing = chart.moonWaxing
        var lines = [String(format: "\(word.prefix(1).uppercased() + word.dropFirst()) Moon, \(waxing ? "waxing (Shukla paksha, getting brighter)" : "waning (Krishna paksha, getting darker)"): \(Names.tithi(chart.day.tithi)), %.0f° from the Sun.", chart.sunGap)]
        lines.append(chart.moonFull ? "Within 30° of the full point: a primary strength." : chart.moonNew ? "Within 30° of the Sun: a primary weakness." : chart.moonBright ? "More than 72° from the Sun and not yet within 30° of full: a bright Moon." : "Within 72° of the Sun: a dark Moon.")
        lines.append(chart.moonBright ? "The brighter the Moon at birth, the more stamina, resilience and tolerance it lends." : "A dark Moon lends greater inward awareness and sensitivity, with less resilience: it asks for more care.")
        return lines
    }

    private var eclipseWords: (text: String, met: Bool) {
        guard let s = chart.syzygy else { return ("", false) }
        let moment = s.solar ? "new Moon" : "full Moon", hours = s.off / 0.508
        let kind = Chart.eclipseKind(solar: s.solar, nodeGap: s.nodeGap), limit = s.solar ? "18°30′" : "12°30′"
        let gap = String(format: "%.1f°", s.nodeGap), light = s.solar ? "The Sun" : "The Moon"
        if s.off < 6, let kind {
            return (String(format: "Born on \(kind): within about %.0f hours of the exact \(moment), with \(light.lowercased()) \(gap) from \(s.node.name). Both lights are read as eclipsed, a primary weakness that turns their light inward.", hours), true)
        }
        if s.off < 6 { return (String(format: "Born within about %.0f hours of the exact \(moment), and no eclipse: \(light.lowercased()) stands \(gap) from \(s.node.name), outside the \(limit) within which one can fall.", hours), false) }
        return (String(format: "Not born on an eclipse: the birth is %.0f° from the exact \(moment), and an eclipse needs it exact. \(light) stands \(gap) from \(s.node.name)\(kind == nil ? "" : ", close enough that the \(moment) of that fortnight was an eclipse or near one").", s.off), false)
    }

    // MARK: the five true planets

    /// degrees from the Sun, 0 to 20, with the three depths of combustion tinted and each planet set at its distance
    private var strip: some View {
        Canvas { context, size in
            let left: CGFloat = 8, width = size.width - 16, scale = width / 20, base: CGFloat = 46
            for (from, to, shade) in [(0.0, 3.0, 0.85), (3.0, 6.0, 0.55), (6.0, 9.0, 0.3)] {
                context.fill(Path(CGRect(x: left + CGFloat(from) * scale, y: base - 8, width: CGFloat(to - from) * scale, height: 16)), with: .color(.orange.opacity(shade)))
            }
            context.stroke(Path { $0.move(to: CGPoint(x: left, y: base)); $0.addLine(to: CGPoint(x: left + width, y: base)) }, with: .color(.secondary), lineWidth: 1)
            for tick in [0, 3, 6, 9, 12, 15, 18] {
                context.draw(Text(tick == 0 ? "Sun" : "\(tick)°").font(.caption2).foregroundColor(.secondary), at: CGPoint(x: left + CGFloat(tick) * scale, y: base + 18))
            }
            for (index, g) in five.filter({ chart.sunDistance($0) < 20 }).sorted(by: { chart.sunDistance($0) < chart.sunDistance($1) }).enumerated() {
                let x = left + CGFloat(chart.sunDistance(g)) * scale, y = base - 20 - CGFloat(index % 2) * 13
                context.stroke(Path { $0.move(to: CGPoint(x: x, y: base - 8)); $0.addLine(to: CGPoint(x: x, y: y + 6)) }, with: .color(Tint.graha(g.id)), lineWidth: 1.5)
                context.draw(Text(g.id + (g.retro ? " R" : "")).font(.caption).fontWeight(g.combust == true ? .bold : .regular).foregroundColor(Tint.graha(g.id)), at: CGPoint(x: x, y: y))
            }
        }
        .frame(width: 420, height: 74)
    }

    private var combustWords: [String] {
        let burnt = five.filter { $0.combust == true }
        var lines = burnt.map { g in
            String(format: "\(name(g.id)): \(chart.combustGrade(g).lowercased()) combust, %.1f° from the Sun", chart.sunDistance(g))
                + (g.nearing == true ? ", still closing on it" : g.nearing == false ? ", already drawing away" : "")
                + (g.retro ? "; retrograde as well, so less weakened than a direct planet this close" : "") + "."
        }
        if burnt.isEmpty { lines.append("None of the five is combust: the nearest to the Sun is " + (five.min { chart.sunDistance($0) < chart.sunDistance($1) }.map { String(format: "\(name($0.id)), %.0f° away", chart.sunDistance($0)) } ?? "far") + ".") }
        return lines
    }

    private var retroWords: [String] {
        let back = five.filter(\.retro)
        guard !back.isEmpty, let sun = chart.graha("Su") else { return ["None of the five is retrograde: all move forward."] }
        return back.map { g in
            let count = (sun.sign - g.sign + 12) % 12 + 1
            return "\(name(g.id)) is retrograde: at its nearest and brightest, a primary strength" + (["Ma", "Ju", "Sa"].contains(g.id) ? "; the Sun stands \(Chart.ordinal(count)) from it" : "") + (g.combust == true ? "; it is combust as well, the one case where a retrograde planet is dim" : "") + "."
        }
    }

    private var warWords: (lines: [String], met: Bool) {
        var lines: [String] = []
        for g in five { if let war = chart.war(of: g), war.prevails {
            let north = { (v: Double?) in v.map { String(format: "%.1f° %@", abs($0), $0 >= 0 ? "north" : "south") } ?? "unread" }
            lines.append(String(format: "\(name(g.id)) and \(name(war.with.id)) are at war, %.2f° apart. \(name(g.id)) stands \(north(g.lat)) of the ecliptic and \(name(war.with.id)) \(north(war.with.lat)): the higher latitude prevails, so \(name(g.id)) wins. Both carry the mark of the fight; the one that yields carries more.", abs(g.lon - war.with.lon)))
        } }
        if !lines.isEmpty { return (lines, true) }
        var best: (Graha, Graha, Double)? = nil
        for (i, a) in five.enumerated() { for b in five.dropFirst(i + 1) { let d = min(abs(a.lon - b.lon), 360 - abs(a.lon - b.lon)); if best == nil || d < best!.2 { best = (a, b, d) } } }
        return (["No planetary war: no two of the five stand within 1° of each other" + (best.map { String(format: "; the closest are \(name($0.0.id)) and \(name($0.1.id)), %.2f° apart", $0.2) } ?? "") + "."], false)
    }

    private func section(_ title: String, met: Bool, helps: Bool, _ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Circle().fill(met ? (helps ? Color.green : Color.orange) : Color.secondary.opacity(0.35)).frame(width: 9, height: 9)
                Text(title).font(.headline)
            }
            ForEach(lines, id: \.self) { Text($0).font(.callout).foregroundStyle(met ? .primary : .secondary).fixedSize(horizontal: false, vertical: true) }
        }
    }

    var body: some View {
        let eclipse = eclipseWords, war = warWords
        HStack(alignment: .top, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                dial
                Text("Orange: new and dark. Green: bright and full. The white dot is the Moon at birth.").font(.caption2).foregroundStyle(.secondary).frame(width: 220, alignment: .leading).fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 12) {
                section("The Moon's light", met: chart.moonFull || chart.moonNew, helps: chart.moonFull, moonWords)
                section("Eclipse", met: eclipse.met, helps: false, [eclipse.text])
                section("Retrogression", met: five.contains(where: \.retro), helps: true, retroWords)
                section("Combustion", met: five.contains { $0.combust == true }, helps: false, combustWords)
                strip
                Text("Degrees from the Sun: 0° to 3° totally combust, 3° to 6° seriously, 6° to 9° generally; beyond that, lightly within each planet's own range. R marks a retrograde planet.").font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                section("Planetary war", met: war.met, helps: false, war.lines)
            }
            .frame(maxWidth: 560, alignment: .leading)
        }
    }
}
