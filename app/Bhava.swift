import SwiftUI

/// Judging a house the way Hart de Fouw and Robert Svoboda teach it in Light on Life, from Phaladipika 15.1 and
/// 15.6: a house is read by three limbs, the house itself, its lord and its karaka. What supports each limb and
/// what asks more of it are set side by side, and the reading is firm where the three agree.
struct Limb: Identifiable {
    let id: String
    let title: String
    var graha: String? = nil
    var supports: [String] = []
    var strains: [String] = []
    /// what is neither for nor against: how the limb works
    var notes: [String] = []
    /// 1 when more speaks for the limb than against it, -1 the other way, 0 when they balance
    var leaning: Int { supports.count == strains.count ? 0 : supports.count > strains.count ? 1 : -1 }
}

extension Lore {
    /// the graha with a natural affinity for each house's main matters (bhava karaka)
    static let bhavaKarakas: [(code: String, matter: String)] = [
        ("Su", "health and vitality"), ("Ju", "wealth and family"), ("Ma", "younger siblings, courage and enterprise"), ("Mo", "the mother and the feelings"),
        ("Ju", "children, counsel and discernment"), ("Ma", "contest, acute illness and litigation"), ("Ve", "marriage and partnership"), ("Sa", "longevity and what endures"),
        ("Ju", "the teacher, dharma and fortune"), ("Su", "standing and authority"), ("Ju", "gains and elder siblings"), ("Sa", "release, distance and letting go"),
    ]
}

extension Chart {
    private func called(_ code: String) -> String { Names.lords[code] ?? code }

    /// the Moon is counted a benefic while waxing
    var moonWaxing: Bool {
        guard let sun = graha("Su"), let moon = graha("Mo") else { return true }
        return (moon.lon - sun.lon + 360).truncatingRemainder(dividingBy: 360) < 180
    }

    /// natural benefic or malefic: Jupiter and Venus are benefics, the Moon while waxing, and Mercury unless it
    /// stands with malefics and no benefic; the Sun, Mars, Saturn, Rahu and Ketu are malefics
    func benefic(_ code: String) -> Bool {
        switch code {
        case "Ju", "Ve": return true
        case "Mo": return moonWaxing
        case "Me":
            guard let me = graha("Me") else { return true }
            let with = grahas.filter { $0.sign == me.sign && $0.id != "Me" }.map(\.id)
            return !with.contains(where: ["Su", "Ma", "Sa", "Ra", "Ke"].contains) || with.contains(where: ["Ju", "Ve"].contains)
        default: return false
        }
    }

    /// why a graha lacks strength in the sense of Phaladipika 15.1: debilitated, combust, or in an enemy's sign
    func weakness(_ g: Graha) -> String? {
        var words: [String] = []
        if g.status == "Debil." { words.append("debilitated") }
        // an enemy's sign is judged by natural enmity toward the sign's lord, as the book's table has it
        if g.status != "Debil.", g.status != "Exalt.", Lore.natural[g.id]?[Chart.signLords[g.sign]] == -1 { words.append("in an enemy's sign") }
        if g.combust == true, g.id != "Mo" { words.append("combust") }
        if g.id == "Mo", !moonBright { words.append("dark, close to the new Moon") }
        return words.isEmpty ? nil : words.joined(separator: " and ")
    }

    /// the lord of the sign a graha stands in, when that is another graha
    func dispositor(of g: Graha) -> Graha? {
        let host = Chart.signLords[g.sign]
        return host == g.id ? nil : graha(host)
    }

    /// what the dispositor adds to a graha, as one line for or against
    func dispositorLine(_ g: Graha) -> (words: String, helps: Bool)? {
        guard let host = dispositor(of: g) else { return nil }
        if let weak = weakness(host) { return ("Its dispositor \(called(host.id)) is \(weak): the ground it stands on asks for tending", false) }
        if host.status == "Exalt." || host.status == "Own" { return ("Its dispositor \(called(host.id)) is \(host.status == "Own" ? "in its own sign" : "exalted"): what it gives is backed", true) }
        return nil
    }

    /// the house itself: who stands in it and aspects it, and what flanks it
    private func houseLimb(_ house: Int) -> Limb {
        let sign = sign(ofHouse: house), lord = lord(ofHouse: house)
        var limb = Limb(id: "house", title: "The house")
        let inside = grahas.filter { $0.sign == sign }.map(\.id), seen = aspecting(sign: sign).filter { !inside.contains($0) }
        for (code, verb) in inside.map({ ($0, "stands in it") }) + seen.map({ ($0, "aspects it") }) {
            let ruled = housesRuled(by: code), article = ["Su", "Mo"].contains(code), who = (article ? "The " : "") + called(code)
            let trine = ruled.filter { [5, 9].contains($0) }, trik = ruled.filter { [6, 8, 12].contains($0) }
            let frail = graha(code).flatMap(weakness).map { ", though it is \($0)" } ?? ""
            if code == lord { limb.supports.append("Its own lord \(article ? "the " : "")\(called(code)) \(verb): a lord looks after its own house\(frail)") }
            else if !trine.isEmpty && trik.isEmpty { limb.supports.append("\(who), lord of the \(trine.map(Chart.ordinal).joined(separator: " and ")), \(verb): a trine lord helps the house it touches\(frail)") }
            else if benefic(code) { limb.supports.append("\(who), a natural benefic, \(verb)\(frail)") }
            else { limb.strains.append("\(who), a natural malefic, \(verb): its matters ask for \(Chart.asks[code] ?? "care")") }
            if code != lord, !trik.isEmpty, !ruled.contains(where: [1, 4, 5, 7, 9, 10].contains), benefic(code) {
                limb.strains.append("\(who) also rules the \(trik.map(Chart.ordinal).joined(separator: " and ")), and brings that house's matters here")
            }
        }
        if let hem = hemming(of: sign, except: "") {
            let names = hem.who.map(called).joined(separator: ", ")
            if hem.helps { limb.supports.append("Flanked by benefics (\(names))") } else { limb.strains.append("Hemmed in between malefics (\(names)): asks for clear boundaries") }
        }
        let places = [4, 8, 12, 5, 9].map { (sign + $0 - 1) % 12 }
        let around = grahas.filter { places.contains($0.sign) && !benefic($0.id) }.map(\.id)
        if around.count >= 4 { limb.strains.append("Most of the malefics stand in the 4th, 8th, 12th or the trines from it (\(around.map(called).joined(separator: ", ")))") }
        let karaka = Lore.bhavaKarakas[house - 1].code
        let kin: [Int: String] = [3: "younger siblings", 4: "the mother", 5: "children", 7: "the partner", 9: "the father", 11: "elder siblings"]
        let own = house == 9 ? "Su" : karaka
        if let who = kin[house], inside.contains(own), Chart.signLords[sign] != own, !(own == "Mo" && moonWaxing) {
            limb.strains.append("\(called(own)), the significator of \(who), stands in the house of \(who): read as asking more care in that relationship")
        }
        if inside.isEmpty && seen.isEmpty { limb.supports.append("No graha stands in it or aspects it: it answers through its lord alone") }
        return limb
    }

    /// a graha as the lord or the karaka of a house: its strength, its placing, its company and its dispositor
    private func grahaLimb(_ g: Graha, id: String, title: String, lordOf: Int? = nil) -> Limb {
        var limb = Limb(id: id, title: title, graha: g.id)
        let house = house(ofSign: g.sign), own = Chart.signLords[g.sign] == g.id
        if let from = lordOf, from != house { limb.notes.append("As lord of the \(Chart.ordinal(from)) placed in the \(Chart.ordinal(house)), it joins the matters of \(Lore.houseNames[from - 1].lowercased()) with those of \(Lore.houseNames[house - 1].lowercased()).") }
        if [3, 6, 10, 11].contains(house) { limb.notes.append("It stands in the \(Chart.ordinal(house)), a growing house (upachaya): what it gives \([3, 6].contains(house) ? "is slow at first and improves with time" : "is good and grows better with time").") }
        if g.status == "Exalt." { limb.supports.append("Exalted in \(Names.signs[g.sign])") }
        if own { limb.supports.append("In its own sign, \(Names.signs[g.sign])") }
        if let weak = weakness(g) { limb.strains.append("\(weak.prefix(1).uppercased() + weak.dropFirst()): \(g.combust == true ? "the outer matters of its houses ask more, while its inner qualities are lit by the Sun" : "it gives through effort")") }
        if [1, 4, 7, 10, 5, 9].contains(house) { limb.supports.append("Placed in the \(Chart.ordinal(house)), \([5, 9].contains(house) ? "a trine" : "an angle")") }
        else if [6, 8, 12].contains(house) {
            if own { limb.supports.append("In the \(Chart.ordinal(house)), yet in its own sign, which holds it") }
            else { limb.strains.append("Placed in the \(Chart.ordinal(house)), a dusthana: it works through \(house == 6 ? "service and effort" : house == 8 ? "depth and renewal" : "release")") }
        }
        if g.retro && !["Ra", "Ke"].contains(g.id) { limb.supports.append("Retrograde: strong in whatever it indicates") }
        if inMulatrikona(g) { limb.supports.append("In its mulatrikona: very strong for good") }
        if let strong = Lore.digBala[g.id], house == strong { limb.supports.append("Directional strength in the \(Chart.ordinal(house))") }
        if g.baladi == "Mrita" { limb.notes.append("It is in Mrita avastha, which tempers what it gives without reversing it.") }
        let company = grahas.filter { $0.sign == g.sign && $0.id != g.id }.map(\.id) + aspecting(sign: g.sign).filter { $0 != g.id }
        let fair = Array(Set(company.filter { benefic($0) })).sorted(), harsh = Array(Set(company.filter { !benefic($0) })).sorted()
        if !fair.isEmpty { limb.supports.append("With or aspected by benefics (\(fair.map(called).joined(separator: ", ")))") }
        if !harsh.isEmpty { limb.strains.append("With or aspected by malefics (\(harsh.map(called).joined(separator: ", "))): asks for steadiness") }
        if let hem = hemming(of: g.sign, except: g.id) {
            let names = hem.who.map(called).joined(separator: ", ")
            if hem.helps { limb.supports.append("Flanked by benefics (\(names))") } else { limb.strains.append("Hemmed in between malefics (\(names))") }
        }
        if let line = dispositorLine(g) { if line.helps { limb.supports.append(line.words) } else { limb.strains.append(line.words) } }
        return limb
    }

    private static let asks: [String: String] = ["Su": "humility", "Ma": "courage and directness", "Sa": "patience and structure", "Ra": "discernment", "Ke": "letting go", "Mo": "steadiness of mind", "Me": "clear thinking"]

    /// the three limbs of a house
    func limbs(ofHouse house: Int) -> [Limb] {
        var list = [houseLimb(house)]
        let lord = lord(ofHouse: house), karaka = Lore.bhavaKarakas[house - 1].code
        if let g = graha(lord) { list.append(grahaLimb(g, id: "lord", title: "Its lord, \(called(lord))", lordOf: house)) }
        if karaka != lord, let g = graha(karaka) { list.append(grahaLimb(g, id: "karaka", title: "Its karaka, \(called(karaka))")) }
        return list
    }

    /// what the limbs say together
    func confluence(ofHouse house: Int) -> String {
        let limbs = limbs(ofHouse: house), leanings = limbs.map(\.leaning), karaka = Lore.bhavaKarakas[house - 1]
        let same = lord(ofHouse: house) == karaka.code ? " Here the lord is also the karaka (\(karaka.matter)), so it counts twice." : ""
        let matters = Lore.houseNames[house - 1].lowercased()
        if leanings.allSatisfy({ $0 > 0 }) { return "House, lord and karaka agree: more speaks for each than against it, so the matters of \(matters) are well supported. Agreement among the limbs is confluence, and it is what makes a reading firm.\(same)" }
        if leanings.allSatisfy({ $0 < 0 }) { return "House, lord and karaka agree in asking more: the matters of \(matters) are where care and steady effort are called for, and where capacity is built. Agreement among the limbs is confluence, and it is what makes a reading firm.\(same)" }
        let words = zip(limbs, leanings).map { "\($0.0.id == "house" ? "the house" : $0.0.id == "lord" ? "the lord" : "the karaka") \($0.1 > 0 ? "is supported" : $0.1 < 0 ? "asks more" : "is balanced")" }.joined(separator: ", ")
        return "The limbs do not agree (\(words)), so no single factor settles the matters of \(matters): they are read as mixed, each limb giving in its own measure.\(same)"
    }
}

/// The three limbs of a house, each with what supports it and what asks more of it.
struct HouseJudgement: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    let house: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(chart.limbs(ofHouse: house)) { limb in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(limb.title).font(.callout).fontWeight(.semibold)
                        if let code = limb.graha {
                            Button("open") { store.pick = .graha(code) }.buttonStyle(.link).font(.caption)
                            if limb.id == "karaka" { Text(Lore.bhavaKarakas[house - 1].matter).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    ForEach(limb.supports, id: \.self) { Label($0, systemImage: "plus.circle").font(.callout).foregroundStyle(.green).labelStyle(FactLabel()) }
                    ForEach(limb.strains, id: \.self) { Label($0, systemImage: "minus.circle").font(.callout).foregroundStyle(.orange).labelStyle(FactLabel()) }
                    ForEach(limb.notes, id: \.self) { Text($0).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
                    if limb.supports.isEmpty && limb.strains.isEmpty { Text("Nothing marked either way.").font(.callout).foregroundStyle(.secondary) }
                }
            }
            Text(chart.confluence(ofHouse: house)).font(.callout).fixedSize(horizontal: false, vertical: true)
            Text("Read as Light on Life teaches from Phaladipika 15.1 and 15.6. Strength says how fully a graha can act; whether it eases or asks more comes from its nature and the houses it rules.")
                .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}
