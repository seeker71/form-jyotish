import SwiftUI

/// Graha strength and weakness as Light on Life teaches it (chapters 4 and 9), laid out the way the book's
/// teaching line sets it on a study sheet: the table of rules with this chart's grahas marked in it, the
/// primary and secondary factors each graha meets, the natural relationships, and three charts that show where
/// each graha is at home, exalted and directionally strong.
extension Lore {
    /// degrees from the Sun within which a graha is combust, direct and retrograde (Light on Life, table 9.1)
    static let combustOrb: [String: (direct: Double, retro: Double)] = ["Ma": (17, 17), "Me": (14, 12), "Ju": (11, 11), "Ve": (10, 8), "Sa": (15, 15)]
    static let five = ["Ma", "Me", "Ju", "Ve", "Sa"]
}

struct KeyFactors {
    var primaryStrength: [String] = [], primaryWeakness: [String] = [], secondaryStrength: [String] = [], secondaryWeakness: [String] = []
}

extension Chart {
    private func apart(_ a: Double, _ b: Double) -> Double { let d = abs(a - b).truncatingRemainder(dividingBy: 360); return d > 180 ? 360 - d : d }
    private func who(_ code: String) -> String { (["Su", "Mo"].contains(code) ? "the " : "") + (Names.lords[code] ?? code) }

    /// degrees between a graha and the Sun
    func sunDistance(_ g: Graha) -> Double { graha("Su").map { apart(g.lon, $0.lon) } ?? 180 }
    /// how far the Moon has gone from the Sun, 0 to 360
    var elongation: Double {
        guard let sun = graha("Su"), let moon = graha("Mo") else { return 90 }
        return (moon.lon - sun.lon + 360).truncatingRemainder(dividingBy: 360)
    }
    /// degrees between the Moon and the Sun, 0 at the new Moon to 180 at the full
    var sunGap: Double { min(elongation, 360 - elongation) }
    /// the Moon's light at birth: new within 30° of the Sun (a primary weakness), dark within 72° of it, full within
    /// 30° of the full point (a primary strength), bright between
    var moonNew: Bool { sunGap < 30 }
    var moonFull: Bool { sunGap > 150 }
    var moonBright: Bool { sunGap >= 72 }
    var moonWord: String { moonNew ? "new" : moonFull ? "full" : moonBright ? "bright" : "dark" }

    /// how far the birth stands from the exact new or full Moon, and how far the lights stand from the nearer node
    var syzygy: (solar: Bool, off: Double, node: Graha, nodeGap: Double)? {
        let solar = sunGap < 90
        guard let light = graha(solar ? "Su" : "Mo"), let node = grahas.suffix(2).min(by: { apart(light.lon, $0.lon) < apart(light.lon, $1.lon) }) else { return nil }
        return (solar, solar ? sunGap : 180 - sunGap, node, apart(light.lon, node.lon))
    }
    /// the kind of eclipse a new or full Moon gives at this distance from a node
    static func eclipseKind(solar: Bool, nodeGap: Double) -> String? {
        let steps: [(Double, String)] = solar ? [(10, "a total solar eclipse"), (12, "a total or partial solar eclipse"), (15.5, "a partial solar eclipse"), (18.5, "a possible partial solar eclipse")]
                                              : [(3.75, "a total lunar eclipse"), (6, "a total or partial lunar eclipse"), (9.5, "a partial lunar eclipse"), (12.5, "a possible partial lunar eclipse")]
        return steps.first { nodeGap < $0.0 }?.1
    }
    /// a luminary born within half a day of an eclipse: the kind of eclipse and the node it fell by
    func eclipsed(_ g: Graha) -> (kind: String, node: String)? {
        guard ["Su", "Mo"].contains(g.id), let s = syzygy, s.off < 6, let kind = Chart.eclipseKind(solar: s.solar, nodeGap: s.nodeGap) else { return nil }
        return (kind, s.node.name)
    }

    /// how deep a combustion is, by degrees from the Sun
    func combustGrade(_ g: Graha) -> String { let d = sunDistance(g); return d < 3 ? "Totally" : d < 6 ? "Seriously" : d < 9 ? "Generally" : "Lightly" }

    /// the first or the last degree of a sign
    func sandhi(_ g: Graha) -> String? { g.deg < 1 ? "first" : g.deg >= 29 ? "last" : nil }

    /// how a graha regards the lord of the sign it stands in, by nature: 1 friend, 0 neutral, -1 enemy; nothing
    /// when it is exalted, debilitated or at home, where the relationship is not what decides
    func naturalRegard(_ g: Graha) -> Int? {
        guard !["Exalt.", "Debil.", "Own"].contains(g.status ?? "Own") else { return nil }
        return Lore.natural[g.id]?[Chart.signLords[g.sign]]
    }

    /// the grahas that share a graha's sign or aspect it, each with its natural leaning
    func company(_ g: Graha) -> [(id: String, joined: Bool, benefic: Bool)] {
        let joined = grahas.filter { $0.sign == g.sign && $0.id != g.id && !($0.id == "Su" && g.combust == true) }.map(\.id)
        let seen = aspecting(sign: g.sign).filter { $0 != g.id && !joined.contains($0) && !($0 == "Su" && g.combust == true) }
        return joined.map { ($0, true, benefic($0)) } + seen.map { ($0, false, benefic($0)) }
    }

    /// the short list a student memorises: what is primary and what is secondary, for and against
    func keyFactors(_ g: Graha) -> KeyFactors {
        var k = KeyFactors()
        let node = ["Ra", "Ke"].contains(g.id), name = { (code: String) in Names.lords[code] ?? code }
        let high = node ? 7 : Lore.exalted[g.id] ?? -1
        if g.sign == high, node || g.status == "Exalt." { k.primaryStrength.append("Exalted") }
        else if g.status == "Own" { k.primaryStrength.append(inMulatrikona(g) ? "Mulatrikona" : "Own sign") }
        if g.retro, Lore.five.contains(g.id) { k.primaryStrength.append("Retrograde") }
        if let strong = Lore.digBala[g.id], house(ofSign: g.sign) == strong { k.primaryStrength.append("Dig bala") }
        if g.id == "Mo", moonFull { k.primaryStrength.append("Full Moon, \(moonWaxing ? "waxing" : "waning")") }
        if g.id == "Mo", !moonFull, !moonNew { if moonBright { k.secondaryStrength.append("Bright Moon, \(moonWaxing ? "waxing" : "waning")") } else { k.secondaryWeakness.append("Dark Moon, \(moonWaxing ? "waxing" : "waning")") } }

        if g.sign == (high + 6) % 12, node || g.status == "Debil." { k.primaryWeakness.append("Debilitated") }
        if g.combust == true, Lore.five.contains(g.id) { k.primaryWeakness.append(String(format: "\(combustGrade(g)) combust, %.1f° from the Sun", sunDistance(g))) }
        if let war = war(of: g), !war.prevails { k.primaryWeakness.append("Lost the war with \(name(war.with.id))") }
        if let eclipse = eclipsed(g) { k.primaryWeakness.append("Born on \(eclipse.kind)") }
        if g.id == "Mo", moonNew { k.primaryWeakness.append("New Moon, \(moonWaxing ? "waxing" : "waning")") }

        let around = company(g)
        for one in around where one.benefic { k.secondaryStrength.append((one.joined ? "With " : "Aspect of ") + name(one.id)) }
        for one in around where !one.benefic { k.secondaryWeakness.append((one.joined ? "With " : "Aspect of ") + name(one.id)) }
        if let regard = naturalRegard(g), regard != 0 {
            let words = "\(regard > 0 ? "Friend" : "Enemy")'s sign (\(name(Chart.signLords[g.sign])))"
            if regard > 0 { k.secondaryStrength.append(words) } else { k.secondaryWeakness.append(words) }
        }
        if let hem = hemming(of: g.sign, except: g.id) { if hem.helps { k.secondaryStrength.append("Flanked by benefics") } else { k.secondaryWeakness.append("Flanked by malefics") } }
        if let war = war(of: g), war.prevails { k.secondaryStrength.append("Won the war with \(name(war.with.id))") }
        if let edge = sandhi(g) { k.secondaryWeakness.append("\(edge.prefix(1).uppercased() + edge.dropFirst()) degree of the sign") }
        return k
    }

    // MARK: the same rules as full sentences, for the lists of what speaks for and against a graha

    /// friendship with the sign's lord: the natural relationship first, as Light on Life's table has it, then what
    /// this chart's temporary friendship adds
    func regardLine(_ g: Graha) -> (words: String, helps: Bool)? {
        guard let regard = naturalRegard(g) else { return nil }
        let host = who(Chart.signLords[g.sign])
        switch (regard, g.status) {
        case (1, let s): return ("In the sign of \(host), its friend by nature: it stands with strength" + (s == "Grt.Fr." ? "; a great friend once this chart's temporary friendship is counted" : "; this chart's temporary enmity draws the compound reckoning back to neutral"), true)
        case (-1, let s): return ("In the sign of \(host), its enemy by nature: it acts with less ease" + (s == "Grt.En." ? "; more so once this chart's temporary enmity is counted" : "; this chart's temporary friendship eases the compound reckoning to neutral"), false)
        case (_, "Friend"): return ("Neutral to \(host) by nature, neither strong nor weak by sign; a friend by this chart's temporary friendship", true)
        case (_, "Enemy"): return ("Neutral to \(host) by nature, neither strong nor weak by sign; at odds by this chart's temporary enmity", false)
        default: return nil
        }
    }

    /// how close the combustion is: the closer, the stronger
    func combustLead(_ g: Graha) -> String {
        let d = sunDistance(g), orb = Lore.combustOrb[g.id].map { g.retro ? $0.retro : $0.direct }
        let depth = d < 3 ? "totally combust (within 3°)" : d < 6 ? "seriously combust (3° to 6°)" : d < 9 ? "generally combust (6° to 9°)" : "lightly, in the outer part of its range" + (orb.map { String(format: " of %.0f°", $0) } ?? "")
        return String(format: "Combust, %.1f° from the Sun, ", d) + depth
    }
    func combustTail(_ g: Graha) -> String {
        (benefic(g.id) ? ". As a natural benefic it gives less of its good the closer it stands" : ". As a natural malefic it presses harder the closer it stands")
            + (g.retro ? ". Retrograde as well, it is less weakened than a direct graha this close" : "")
    }

    func retroWords(_ g: Graha) -> String {
        "Retrograde: near the earth, and strong in whatever it indicates; " + (benefic(g.id) ? "a natural benefic so placed gains power to give" : "a natural malefic so placed gains power to press")
            + (g.status == "Debil." ? ". Debilitated as well, it keeps part of this strength, most for the good houses it rules"
               : g.status == "Exalt." ? ". Exalted as well, it is doubly strong; whether for ease or for effort is read from the houses it rules" : "")
    }

    /// who shares the sign or aspects it, by natural leaning
    func companyLines(_ g: Graha) -> (supports: [String], strains: [String]) {
        var supports: [String] = [], strains: [String] = []
        let asks = ["Sa": "patience and structure", "Ma": "courage and directness", "Su": "clarity about what is one's own", "Mo": "steadiness of mind, the Moon being dark", "Me": "discernment, Mercury standing with malefics"]
        for one in company(g) {
            let name = Names.lords[one.id] ?? one.id, verb = one.joined ? "Joined by" : "Aspected by"
            if one.id == "Ra" || one.id == "Ke" { strains.append("Shares its sign with \(name): \(one.id == "Ra" ? "amplified, unconventional" : "turned inward")") }
            else if one.benefic { supports.append("\(verb) \(name), a natural benefic") }
            else { strains.append("\(verb) \(name), a natural malefic: asks for \(asks[one.id] ?? "care")") }
        }
        return (supports, strains)
    }

    /// the Moon's light, an eclipse, a joint between two signs, and malefics set around a graha
    func lightAndJoint(_ g: Graha) -> (supports: [String], strains: [String]) {
        var supports: [String] = [], strains: [String] = []
        if g.id == "Mo" {
            let facts = String(format: "\(moonWaxing ? "waxing" : "waning"), \(Names.tithi(day.tithi)), %.0f° from the Sun", sunGap)
            if moonFull { supports.append("Full Moon (\(facts)): within 30° of the full point, a primary strength: stamina, resilience and plenty of light for outer matters") }
            else if moonBright { supports.append("Bright Moon (\(facts)): more than 72° from the Sun, with light enough to give steadily") }
            else if moonNew { strains.append("New Moon (\(facts)): within 30° of the Sun, a primary weakness: little light for outer matters, a mind turned inward that asks for more care") }
            else { strains.append("Dark Moon (\(facts)): within 72° of the Sun: more inward and sensitive, with less stamina for outer matters") }
        }
        if let eclipse = eclipsed(g) { strains.append("Born on \(eclipse.kind) by \(eclipse.node): \(who(g.id)) is read as eclipsed, its light turned inward") }
        if let edge = sandhi(g), !Chart.gandanta(sign: g.sign, deg: g.deg) { strains.append("In the \(edge) degree of \(Names.signs[g.sign]), a joint between two signs (sandhi): ill-defined for outer matters, often apt for inner work") }
        let harsh = { (count: Int) in self.grahas.contains { $0.id != g.id && $0.sign == (g.sign + count - 1) % 12 && !self.benefic($0.id) } }
        if harsh(4) && harsh(8) && harsh(12) { strains.append("Malefics stand in the 4th, 8th and 12th from it (Phaladipika 15)") }
        else if harsh(5) && harsh(9) { strains.append("Malefics stand in the 5th and 9th from it (Phaladipika 15)") }
        return (supports, strains)
    }
}

// MARK: the cards

/// One cell of a study table: a rule, lit when this chart meets it.
private struct SheetCell: View {
    var text: String
    var width: CGFloat
    var met = false
    var helps = true
    var header = false
    var tint: Color? = nil

    var body: some View {
        let colour: Color = helps ? .green : .orange
        Text(text)
            .font(header ? .caption : .callout)
            .fontWeight(met || tint != nil ? .semibold : .regular)
            .foregroundStyle(header ? AnyShapeStyle(.secondary) : tint.map { AnyShapeStyle($0) } ?? (met ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary)))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 5).padding(.vertical, 3)
            .frame(width: width, alignment: .topLeading)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .background(met ? colour.opacity(0.18) : Color.clear)
    }
}

private struct SheetRow: View {
    @EnvironmentObject var store: Store
    var graha: String?
    var cells: [SheetCell]

    var body: some View {
        let near = graha != nil && (store.pick?.graha == graha || store.hover?.graha == graha)
        HStack(alignment: .top, spacing: 1) { ForEach(cells.indices, id: \.self) { cells[$0] } }
            .fixedSize(horizontal: false, vertical: true)
            .background(near ? Color.accentColor.opacity(0.10) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { if let graha { store.pick = .graha(graha) } }
            .onHover { inside in if let graha { store.hover = inside ? .graha(graha) : nil } }
    }
}

/// The table of rules: where each graha is at home, exalted, directionally strong and debilitated, and whether it
/// is retrograde, combust or at war; a cell is lit where this chart's graha meets the rule.
struct StrengthSheet: View {
    let chart: Chart
    private let widths: [CGFloat] = [66, 124, 78, 84, 86, 84, 112, 112]

    private func cells(_ g: Graha) -> [SheetCell] {
        let node = ["Ra", "Ke"].contains(g.id), five = Lore.five.contains(g.id), name = { (code: String) in Names.lords[code] ?? code }
        let own = (0..<12).filter { Chart.signLords[$0] == g.id }, high = node ? 7 : Lore.exalted[g.id] ?? 0, house = chart.house(ofSign: g.sign)
        var list = [SheetCell(text: name(g.id), width: widths[0], tint: Tint.graha(g.id))]
        list.append(SheetCell(text: node ? "—" : own.map { Names.signs[$0] }.joined(separator: ", "), width: widths[1], met: own.contains(g.sign)))
        list.append(SheetCell(text: Names.signs[high], width: widths[2], met: g.sign == high))
        if let strong = Lore.digBala[g.id] {
            let opposite = (strong + 5) % 12 + 1
            list.append(SheetCell(text: house == opposite ? "\(Chart.ordinal(strong)); here \(Chart.ordinal(house)), without it" : "\(Chart.ordinal(strong)) house", width: widths[3], met: house == strong || house == opposite, helps: house == strong))
        } else { list.append(SheetCell(text: "—", width: widths[3])) }
        list.append(SheetCell(text: five ? (g.retro ? "Retrograde" : "direct") : "—", width: widths[4], met: five && g.retro))
        list.append(SheetCell(text: Names.signs[(high + 6) % 12], width: widths[5], met: g.sign == (high + 6) % 12, helps: false))
        let orb = Lore.combustOrb[g.id].map { g.retro ? $0.retro : $0.direct }
        list.append(SheetCell(text: !five ? "—" : g.combust == true ? String(format: "\(chart.combustGrade(g)) combust, %.1f° from the Sun", chart.sunDistance(g)) : String(format: "clear: %.0f° away, range %.0f°", chart.sunDistance(g), orb ?? 0), width: widths[6], met: five && g.combust == true, helps: false))
        let war = chart.war(of: g)
        list.append(SheetCell(text: !five ? "—" : war.map { ($0.prevails ? "Prevails over " : "Yields to ") + name($0.with.id) } ?? "none", width: widths[7], met: war != nil, helps: war?.prevails ?? true))
        return list
    }

    var body: some View {
        let moon = chart.graha("Mo"), lights = chart.grahas.prefix(2).compactMap { g in chart.eclipsed(g).map { "\(Names.lords[g.id] ?? g.id) born on \($0.kind) by \($0.node)" } }
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                SheetRow(graha: nil, cells: zip(["Graha", "Own sign (+)", "Exaltation (+)", "Dig bala (+)", "Retrograde (+)", "Debilitated (−)", "Combustion (−)", "Planetary war (±)"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                ForEach(chart.grahas) { g in SheetRow(graha: g.id, cells: cells(g)) }
                Text("Sun and Moon take no retrogression, combustion or war; their further measure is the Moon's light and eclipses. Here the Moon is \(chart.moonWaxing ? "waxing" : "waning") and \(chart.moonWord) (\(Names.tithi(chart.day.tithi))\(moon == nil ? "" : String(format: ", %.0f° from the Sun", chart.elongation > 180 ? 360 - chart.elongation : chart.elongation)))\(lights.isEmpty ? "; neither light is eclipsed" : "; " + lights.joined(separator: ", ")). A lit cell is a rule this chart meets: green adds strength, orange asks more.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    .frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 6)
            }
        }
    }
}

/// What each graha meets of the primary and the secondary factors.
struct KeyFactorsCard: View {
    let chart: Chart
    private let widths: [CGFloat] = [66, 130, 176, 150, 170]
    static let legend = [
        ("Primary strength", "own sign, exaltation, retrogression, dig bala, full Moon"),
        ("Primary weakness", "debilitation, combustion, losing a planetary war, eclipse, new Moon"),
        ("Secondary strength", "joined or aspected by a natural benefic, a friend's sign, flanked by benefics, winning a planetary war"),
        ("Secondary weakness", "joined or aspected by a natural malefic, an enemy's sign, flanked by malefics, first or last degree of a sign")]

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                SheetRow(graha: nil, cells: zip(["Graha"] + Self.legend.map(\.0), widths).map { SheetCell(text: $0, width: $1, header: true) })
                ForEach(chart.grahas) { g in
                    let k = chart.keyFactors(g), show = { (list: [String]) in list.isEmpty ? "·" : list.joined(separator: "\n") }
                    SheetRow(graha: g.id, cells: [
                        SheetCell(text: Names.lords[g.id] ?? g.id, width: widths[0], tint: Tint.graha(g.id)),
                        SheetCell(text: show(k.primaryStrength), width: widths[1], met: !k.primaryStrength.isEmpty),
                        SheetCell(text: show(k.primaryWeakness), width: widths[2], met: !k.primaryWeakness.isEmpty, helps: false),
                        SheetCell(text: show(k.secondaryStrength), width: widths[3], met: !k.secondaryStrength.isEmpty),
                        SheetCell(text: show(k.secondaryWeakness), width: widths[4], met: !k.secondaryWeakness.isEmpty, helps: false)])
                }
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Self.legend, id: \.0) { item in Text("\(Text(item.0).fontWeight(.semibold)): \(item.1).") }
                    Text("Strength is a graha's power to act, not its intent: a strong graha gives fully what it stands for in this chart, by its nature and by the houses it rules.")
                }
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                .frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 6)
            }
        }
    }
}

/// The natural relationships, and whose guest each graha is in this chart.
struct RelationsCard: View {
    let chart: Chart
    private let widths: [CGFloat] = [66, 140, 170, 120, 220]

    private func here(_ g: Graha) -> (text: String, met: Bool, helps: Bool) {
        let sign = Names.signs[g.sign], host = Names.lords[Chart.signLords[g.sign]] ?? ""
        switch g.status {
        case "Exalt.": return ("Exalted in \(sign)", true, true)
        case "Debil.": return ("Debilitated in \(sign)", true, false)
        case "Own": return ("At home in \(sign)", true, true)
        default:
            let regard = chart.naturalRegard(g) ?? 0
            return ("Guest of \(host) in \(sign): \(regard > 0 ? "a friend" : regard < 0 ? "an enemy" : "a neutral")", regard != 0, regard > 0)
        }
    }

    var body: some View {
        let seven = Array(chart.grahas.prefix(7)), names = { (g: Graha, regard: Int) in seven.filter { Lore.natural[g.id]?[$0.id] == regard }.map { Names.lords[$0.id] ?? $0.id }.joined(separator: ", ") }
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                SheetRow(graha: nil, cells: zip(["Graha", "Friends (mitra)", "Neutrals (sama)", "Enemies (shatru)", "In this chart"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                ForEach(seven) { g in
                    let place = here(g)
                    SheetRow(graha: g.id, cells: [
                        SheetCell(text: Names.lords[g.id] ?? g.id, width: widths[0], tint: Tint.graha(g.id)),
                        SheetCell(text: names(g, 1), width: widths[1]), SheetCell(text: names(g, 0), width: widths[2]),
                        SheetCell(text: names(g, -1).isEmpty ? "none" : names(g, -1), width: widths[3]),
                        SheetCell(text: place.text, width: widths[4], met: place.met, helps: place.helps)])
                }
                Text("Read a row from the left: the graha is the guest, and the lord of the sign it stands in is its host. The regard is not always returned: Saturn holds Mercury as a friend's host, while Mercury is neutral to Saturn. Rahu and Ketu have no relationships set by tradition; some read Rahu by Saturn's and Ketu by Mars's. A memory aid: Sun, Moon, Mars and Jupiter form one camp, Saturn, Venus and Mercury the other; grahas tend to be friendly within a camp and cool across.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    .frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 6)
            }
        }
    }
}

/// Three charts on this chart's lagna: the lord of each sign, the sign where each graha is exalted, and the house
/// where each has directional strength. A graha that stands there in this chart is ticked.
struct StrengthCharts: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private func mark(_ code: String, in sign: Int) -> ChartMark {
        let there = chart.graha(code)?.sign == sign
        return ChartMark(code: code, label: code + (there ? " ✓" : ""))
    }
    private var own: [Int: [ChartMark]] { Dictionary(uniqueKeysWithValues: (0..<12).map { ($0, [mark(Chart.signLords[$0], in: $0)]) }) }
    private var exalted: [Int: [ChartMark]] {
        var marks: [Int: [ChartMark]] = [:]
        for (code, sign) in Lore.exalted { marks[sign, default: []].append(mark(code, in: sign)) }
        for code in ["Ra", "Ke"] { marks[7, default: []].append(mark(code, in: 7)) }
        return marks.mapValues { $0.sorted { $0.code < $1.code } }
    }
    private var directional: [Int: [ChartMark]] {
        var marks: [Int: [ChartMark]] = [:]
        for (code, house) in Lore.digBala { let sign = chart.sign(ofHouse: house); marks[sign, default: []].append(mark(code, in: sign)) }
        return marks.mapValues { $0.sorted { $0.code < $1.code } }
    }
    private func met(_ test: (Graha) -> Bool) -> String {
        let list = chart.grahas.filter(test).map { Names.lords[$0.id] ?? $0.id }
        return list.isEmpty ? "none" : list.joined(separator: ", ")
    }

    private func panel(_ title: String, _ marks: [Int: [ChartMark]], _ words: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            ChartView(style: store.style, title: "", ascSign: chart.asc.sign, marks: marks).frame(width: 250, height: 250)
            Text(words).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 250, alignment: .leading)
        }
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 18) {
                panel("Own sign (sva-rashi)", own, "The lord of each sign, set on this chart's lagna. A graha at home is steady and gives well. At home here: \(met { Chart.signLords[$0.sign] == $0.id }).")
                panel("Exaltation (uccha)", exalted, "Each graha is debilitated in the sign opposite. How fully an exaltation gives, or how much a debilitation asks, also rests on the lord of that sign. Exalted here: \(met { $0.sign == (["Ra", "Ke"].contains($0.id) ? 7 : Lore.exalted[$0.id] ?? -1) }); debilitated: \(met { $0.sign == ((["Ra", "Ke"].contains($0.id) ? 7 : Lore.exalted[$0.id] ?? -7) + 6) % 12 }).")
                panel("Directional strength (dig bala)", directional, "Mercury and Jupiter at the rising, Sun and Mars at midday, Saturn at the setting, Moon and Venus at midnight; each is without it in the house opposite. It is counted by house, so it holds even for a graha that is combust or debilitated. With dig bala here: \(met { Lore.digBala[$0.id] == chart.house(ofSign: $0.sign) }).")
            }
        }
    }
}
