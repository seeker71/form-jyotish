import SwiftUI

/// The finer measures of a graha's strength that Light on Life takes from Parashara: the mulatrikona, the positive
/// and negative own sign, directional strength, the measure each baladi avastha gives, planetary war, and the
/// dignity of the nodes.
extension Lore {
    /// the part of a sign where each graha has trinal strength (Parashara)
    static let mulatrikona: [String: (sign: Int, from: Double, to: Double)] = [
        "Su": (4, 0, 20), "Mo": (1, 4, 30), "Ma": (0, 0, 12), "Me": (5, 16, 20), "Ju": (8, 0, 10), "Ve": (6, 0, 15), "Sa": (10, 0, 20),
    ]
    /// the own sign in which each of the five is the more favourable
    static let positiveSign: [String: Int] = ["Ma": 0, "Me": 2, "Ju": 8, "Ve": 6, "Sa": 10]
    /// the house where each graha has directional strength; it is without it in the house opposite
    static let digBala: [String: Int] = ["Me": 1, "Ju": 1, "Mo": 4, "Ve": 4, "Sa": 7, "Su": 10, "Ma": 10]
    /// about how much of its potential a graha shows by dignity
    static let dignityScale: [String: String] = [
        "Exalt.": "seven-eighths to the whole", "Own": "a half to three-quarters", "Grt.Fr.": "three-eighths to a half", "Friend": "three-eighths to a half",
        "Neutr.": "a quarter to three-eighths", "Enemy": "an eighth to a quarter", "Grt.En.": "an eighth to a quarter", "Debil.": "up to an eighth",
    ]
}

extension Chart {
    /// whether a graha stands in its mulatrikona
    func inMulatrikona(_ g: Graha) -> Bool {
        guard let part = Lore.mulatrikona[g.id] else { return false }
        return g.sign == part.sign && g.deg >= part.from && g.deg < part.to
    }

    /// a graha within one degree of another of the five: planetary war. The graha with the higher latitude prevails,
    /// the rule Light on Life gives; `differs` says the lower-longitude rule of many books would name the other.
    func war(of g: Graha) -> (with: Graha, prevails: Bool, differs: Bool)? {
        let five = ["Ma", "Me", "Ju", "Ve", "Sa"]
        guard five.contains(g.id), let other = grahas.first(where: { $0.id != g.id && five.contains($0.id) && $0.sign == g.sign && abs($0.lon - g.lon) < 1 }) else { return nil }
        let byLongitude = g.lon < other.lon
        guard let mine = g.lat, let theirs = other.lat else { return (other, byLongitude, false) }
        return (other, mine > theirs, (mine > theirs) != byLongitude)
    }

    /// the finer measures, as lines for and against
    func finer(_ g: Graha) -> (supports: [String], strains: [String]) {
        var supports: [String] = [], strains: [String] = []
        let house = house(ofSign: g.sign), name = { (code: String) in Names.lords[code] ?? code }
        if inMulatrikona(g) { supports.append("In its mulatrikona, the part of \(Names.signs[g.sign]) where it is strongest for good") }
        else if g.status == "Own", let positive = Lore.positiveSign[g.id] {
            supports.append(g.sign == positive ? "\(Names.signs[g.sign]) is its positive sign, the more favourable of the two it rules" : "\(Names.signs[g.sign]) is its negative sign, a little less favourable than its other")
        }
        if let strong = Lore.digBala[g.id] {
            if house == strong { supports.append("Directional strength (dig bala): in the \(Chart.ordinal(house)) it acts with full force") }
            if house == (strong + 5) % 12 + 1 { strains.append("Without directional strength in the \(Chart.ordinal(house)): it acts with less force") }
        }
        switch g.baladi {
        case "Yuva": supports.append("Yuva avastha, the adult: it gives in full")
        case "Bala": strains.append("Bala avastha, the infant: it shows about a quarter of its strength" + (g.navamsa == g.sign ? "; it is vargottama there, which greatly lifts this state" : ""))
        case "Vriddha": strains.append("Vriddha avastha, the aged: it gives in small measure")
        case "Mrita": strains.append("Mrita avastha, the spent: it gives least; an avastha tempers a reading and does not reverse it" + (g.navamsa == g.sign ? "; it is vargottama there, which greatly lifts this state" : ""))
        default: break
        }
        if let war = war(of: g) {
            let north = { (v: Double?) in v.map { String(format: "%.1f° %@", abs($0), $0 >= 0 ? "north" : "south") } ?? "unread" }
            let words = "Within one degree of \(name(war.with.id)): planetary war. The graha with the higher latitude prevails: \(name(g.id)) stands \(north(g.lat)) of the ecliptic and \(name(war.with.id)) \(north(war.with.lat)), so \(name(war.prevails ? g.id : war.with.id)) prevails\(war.differs ? "; the lower-longitude rule that many books use would name the other" : "")"
            if war.prevails { supports.append(words) } else { strains.append(words) }
        }
        if Chart.gandanta(sign: g.sign, deg: g.deg) { strains.append("At a gandanta, the joint of a water sign and a fire sign: weak for outer matters, apt for inner work") }
        if g.id == "Ra" || g.id == "Ke" {
            if g.sign == 7 { supports.append("Exalted in Vrischika, by the scheme Light on Life follows for both nodes") }
            if g.sign == 1 { strains.append("Debilitated in Vrishabha, by the scheme Light on Life follows for both nodes") }
        }
        return (supports, strains)
    }
}
