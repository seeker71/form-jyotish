import SwiftUI

/// Lagna vichara and bhava vichara: the rising sign read through its lord, and the rules by which a house is
/// analysed (natural and temporal benefics and malefics, karakas, stability, the lord that protects its own),
/// each applied to this chart. After Light on Life, chapters 6 and 9.
extension Lore {
    /// each lagna in a few strokes: what it does, the image, what marks its people, where it is hardest, the body
    static let lagnaLore: [(verb: String, image: String, traits: [String], hardest: String, body: String)] = [
        ("initiates", "The ram: active and on the move, outwardly, inwardly or both", ["original and independent", "loves freedom and adventure", "courage; protects self and others and fights for what is right", "dynamic and strong-willed, a person of action", "fire is the key element: passion, ambition, heat", "wants things to happen now"], "restless, hot-tempered and impatient; my way or none", "pitta: out of balance it shows as inflammation, rashes, liver and blood trouble, burnout"),
        ("stabilises", "The bull: strength, of body or of mind", ["slow to anger, a force once roused", "loves harmony, comfort, food and beauty", "a sharp mind, used to earn; can write well", "strong pursuit of knowledge and career", "romantic and artistic", "early dependence that is outgrown in time"], "harmony at any price: avoiding conflict and giving up one's own ground to keep a relationship; care is asked with children, elder siblings and friends", "a sturdy build, often with a broad neck or shoulders"),
        ("communicates", "The pair: two natures blended in one, and often two minds", ["loves information, study, letters and numbers", "at home in business and trade", "of two minds about relationships, residence and above all career", "drawn to the arts", "talkative; enjoys life's pleasures", "prefers philosophy to devotion"], "relying on the intellect alone, speech that runs ahead of judgement, scattered effort", "the nervous system and the skin; health wavers when it is not attended to"),
        ("nurtures", "The crab: a firm shell over a pool of feeling", ["sensitive, intuitive, acts on instinct", "changeable as the Moon", "nurturing, or seeking to be nurtured", "regal, with a natural gift to lead", "works with people and the public", "home, family and friends matter greatly"], "feeling clouds thinking in a crisis; moods; partnerships kept private", "a watery, kapha constitution; the chest and stomach"),
        ("leads", "The lion: a striking presence and a regal manner", ["a strong sense of self", "drawn to leadership, politics or government", "expects to be served, and gives as a sovereign gives", "fortunate with land and property", "an interest in spiritual life; the father is often a person of weight"], "more show than courage, little room left for others, a wish to rule the partnership", "a fiery, pitta constitution; the heart and the upper abdomen"),
        ("refines", "The maiden: modest, drawn to purity, with wheat in one hand and fire in the other", ["analysis, calculation and detail", "skill at a trade; health care, hygiene and service", "loves classical learning", "particular about food", "thinks unusual thoughts and resists set procedure", "led by the head more than the heart in matters of faith"], "over-exactness; marriage and children ask care, and so do accidents", "an earthy, vata constitution; the digestion and the nerves"),
        ("balances", "The scales: the merchant who weighs and exchanges", ["harmony, peace and balance are the themes", "justice and conciliation", "affectionate, even-tempered, courteous", "public professions and politics", "friends, clubs and societies are important", "conscious of style; marriage tends to endure"], "spending money and strength too freely, being led by company, slow to take counsel, avoiding conflict", "airy, of mixed doshas; the lower abdomen"),
        ("transforms", "The scorpion: a firm shell with potency within", ["independent and private", "unorthodox in religion and philosophy; avoids the usual procedure", "powerful feelings, loyal, determined", "drawn to what transforms: medicine, healing, research, the hidden", "brave and ambitious, a person of action", "tends to move away from the birthplace"], "restless, hot-tempered, extreme, quarrelsome", "pitta: inflammation, rashes, liver and blood trouble, burnout"),
        ("aims", "The archer: prevails over opposition by winning it over", ["optimistic, philosophical, compassionate", "frank and to the point; dislikes hypocrisy and show", "generally fortunate", "generous, sometimes past what the purse allows", "a career of the mind or of communication, sometimes two careers", "finds happiness in spiritual or religious pursuit"], "indecisive, careless, boastful, tactless", "kapha with pitta: weight, the liver, blood sugar"),
        ("builds", "The makara, at home in two elements: ambition is strong", ["patient, steady progress that ripens late", "drawn to tradition and to old cultures", "careful with money; gains through property", "devoted to children", "deep thinking, perseverance, responsibility, planning"], "aloof and private; unsettled about home and roots; practical more than close in relationships", "vata: a slender frame and stiff joints that ask for oiling and stretching"),
        ("gathers", "The pot that holds what is poured into it: gathers knowledge above all", ["drawn to science and expertise", "friends, clubs, societies and social duty matter", "not much moved by money; gains alternate with losses", "progress in career is slow", "a way of one's own, often kept private", "deep thinking, patience, planning"], "aloof, secretive or timid; practical more than committed in relationships", "vata: a slender frame and stiff joints that ask for oiling and stretching"),
        ("unites", "Two fish swimming opposite ways: two ideals held at once", ["optimistic, philosophical, compassionate", "generally fortunate; visionary, honest, well-spoken", "loves to teach and to learn", "poetry, wisdom, medicine and places of healing", "fine bonds with children", "wins over opponents without force"], "indecisive, too passive, with soft boundaries; let down by friends; home or schooling may be unsettled", "kapha: weight, growths, blood sugar, the liver"),
    ]
    static let positiveHouses: Set<Int> = [1, 2, 4, 5, 7, 9, 10, 11], negativeHouses: Set<Int> = [3, 6, 8, 12]
}

private extension Array where Element == String {
    /// joined with commas, each item beginning in lower case and names kept as they are
    var listed: String { map { $0.prefix(1).lowercased() + $0.dropFirst() }.joined(separator: ", ") }
}

extension Chart {
    /// the houses a graha rules, split into the positive ones and the ones that ask more
    func temporal(_ code: String) -> (positive: [Int], negative: [Int]) {
        let ruled = housesRuled(by: code)
        return (ruled.filter(Lore.positiveHouses.contains), ruled.filter(Lore.negativeHouses.contains))
    }
    func temporalWord(_ code: String) -> String {
        let t = temporal(code)
        return t.negative.isEmpty ? "temporal benefic only" : t.positive.isEmpty ? "temporal malefic only" : "both: benefic for the \(t.positive.map(Chart.ordinal).joined(separator: ", ")), malefic for the \(t.negative.map(Chart.ordinal).joined(separator: ", "))"
    }

    /// what a house lord gives from where it stands, by the rules for temporal benefics and malefics
    func temporalResult(_ g: Graha) -> String {
        let t = temporal(g.id), house = house(ofSign: g.sign), good = Lore.positiveHouses.contains(house), list = { (h: [Int]) in h.map(Chart.ordinal).joined(separator: " and ") }
        var parts: [String] = []
        if !t.positive.isEmpty { parts.append(good ? "As lord of the \(list(t.positive)) in a positive house it promotes the desirable side of what it rules there" : "As lord of the \(list(t.positive)) in a house that asks more, the harder side of those matters comes forward") }
        if !t.negative.isEmpty { parts.append(good ? "As lord of the \(list(t.negative)) in a positive house it gives both sides of those matters" : "As lord of the \(list(t.negative)) in a house that asks more, the harder side of those matters is contained") }
        if t.negative.isEmpty { parts.append("Owning positive houses only, it lifts what it joins or aspects") } else if t.positive.isEmpty { parts.append("Owning only houses that ask more, it presses on what it joins or aspects") }
        return parts.joined(separator: ". ") + "."
    }

    /// what steadies a graha and what unsettles it: natural benefics or malefics with, aspecting or flanking it, and a friend's or an enemy's rashi
    func stability(_ g: Graha) -> String {
        let k = keyFactors(g), steady = k.secondaryStrength.filter { !$0.contains("Moon,") && !$0.contains("war") }, shaken = k.secondaryWeakness.filter { !$0.contains("Moon,") && !$0.contains("degree") }
        if steady.isEmpty && shaken.isEmpty { return "nothing marked either way" }
        return (steady.isEmpty ? "" : "Steadied: " + steady.listed) + (steady.isEmpty || shaken.isEmpty ? "" : "\n") + (shaken.isEmpty ? "" : "Unsettled: " + shaken.listed)
    }

    /// a graha in its own sign, or aspecting it, protects that house even when it is a natural malefic
    var protectors: [String] {
        var lines: [String] = []
        for g in grahas.prefix(7) {
            let name = Names.lords[g.id] ?? g.id
            if Chart.signLords[g.sign] == g.id { lines.append("\(name) stands in its own \(Names.signs[g.sign]) and protects the \(housesRuled(by: g.id).map(Chart.ordinal).joined(separator: " and ")) house\(housesRuled(by: g.id).count > 1 ? "s" : "")\(benefic(g.id) ? "" : ", malefic by nature though it is").") }
            for house in housesRuled(by: g.id) where sign(ofHouse: house) != g.sign && aspecting(sign: sign(ofHouse: house)).contains(g.id) {
                lines.append("\(name) aspects its own \(Names.signs[sign(ofHouse: house)]) and protects the \(Chart.ordinal(house)) house.")
            }
        }
        return lines.isEmpty ? ["No graha stands in or aspects its own sign in this chart: no house has that protection."] : lines
    }

    /// the house, its lord and its karakas weighed as forty, forty and twenty parts in a hundred
    func weighed(ofHouse house: Int) -> (score: Double, words: String) {
        let limbs = limbs(ofHouse: house), h = Double(limbs.first { $0.id == "house" }?.leaning ?? 0), l = limbs.first { $0.id == "lord" }.map { Double($0.leaning) }
        let karakas = limbs.filter { $0.id.hasPrefix("karaka") }.map { Double($0.leaning) }, k = karakas.isEmpty ? nil : karakas.reduce(0, +) / Double(karakas.count)
        let score: Double = k == nil ? 0.5 * h + 0.5 * (l ?? h) : 0.4 * h + 0.4 * (l ?? h) + 0.2 * k!
        let verdict = score > 0.2 ? "leans supported" : score < -0.2 ? "leans toward asking more" : "stands balanced"
        return (score, String(format: " Weighed as house 40, lord 40 and karaka 20 parts in a hundred, the matter \(verdict) (%+.1f on a scale of −1 to +1).", score))
    }
}

/// The rising sign read through its lord: what the lagna is, who rules it, where the ruler has gone and how
/// strong it stands, with the lagna's own nature.
struct LagnaVicharaCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private func point(_ head: String, _ words: String) -> some View {
        (Text(head + " ").fontWeight(.semibold) + Text(words)).font(.callout).fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        let lagna = chart.asc.sign, code = chart.lord(ofHouse: 1), lore = Lore.lagnaLore[lagna], name = Names.lords[code] ?? code
        let high = Lore.exalted[code] ?? 0, low = (high + 6) % 12, own = (0..<12).filter { Chart.signLords[$0] == code }
        var marks: [Int: [ChartMark]] = [:]
        for sign in own { marks[sign, default: []].append(ChartMark(code: "o\(sign)", label: "Own", sign: sign, note: "\(name)'s own sign: the \(Chart.ordinal(chart.house(ofSign: sign))) house")) }
        marks[high, default: []].append(ChartMark(code: "x", label: "Exalted", sign: high, note: "\(name) is exalted here, in the \(Chart.ordinal(chart.house(ofSign: high))) house"))
        marks[low, default: []].append(ChartMark(code: "d", label: "Debil.", sign: low, note: "\(name) is debilitated here, in the \(Chart.ordinal(chart.house(ofSign: low))) house"))
        if let g = chart.graha(code) { marks[g.sign, default: []].append(ChartMark(code: code, label: code + " ●")) }
        let lord = chart.graha(code), k = lord.map { chart.keyFactors($0) }, widths: [CGFloat] = [70, 120, 110, 250]
        let word = { (n: Int?) in n == nil ? "none set" : n! > 0 ? "a friend" : n! < 0 ? "an enemy" : "neutral" }
        return ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(Names.signs[lagna]) lagna · \(name) \(lore.verb)").font(.headline)
                    ChartView(style: store.style, title: "", ascSign: lagna, marks: marks).frame(width: 300, height: 300)
                    Text("Where the lagna lord is at home, exalted and debilitated in this lagna, and (●) where it stands in this chart.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 300, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 9) {
                    Text("Four questions").font(.headline)
                    point("What is the lagna?", "\(Names.signs[lagna]) (\(Names.signsWestern[lagna])), a \(Lore.modes[lagna % 3]) \(Lore.elements[lagna % 4]) rashi. \(lore.image).")
                    point("Who is its lord?", "\(name), \(Lore.grahaMeanings[code]?.essence ?? ""); it also rules the \(chart.housesRuled(by: code).filter { $0 != 1 }.map(Chart.ordinal).joined(separator: " and ").isEmpty ? "1st alone" : chart.housesRuled(by: code).filter { $0 != 1 }.map(Chart.ordinal).joined(separator: " and ")).")
                    if let lord {
                        point("Where has it gone?", "To the \(Chart.ordinal(chart.house(ofSign: lord.sign))) house, \(Names.signs[lord.sign]): the person's attention goes to \(Lore.houses[chart.house(ofSign: lord.sign) - 1]). That house is \(Lore.houseClasses(chart.house(ofSign: lord.sign)).map { $0.name.lowercased() }.joined(separator: ", ")).")
                        point("What is its strength?", "Primary strength: \(k!.primaryStrength.isEmpty ? "none" : k!.primaryStrength.listed). Primary weakness: \(k!.primaryWeakness.isEmpty ? "none" : k!.primaryWeakness.listed). Secondary: \((k!.secondaryStrength + k!.secondaryWeakness).isEmpty ? "none" : (k!.secondaryStrength + k!.secondaryWeakness).listed).")
                    }
                    Text("The nature of \(Names.signs[lagna]) lagna").font(.headline).padding(.top, 4)
                    ForEach(lore.traits, id: \.self) { Text("• " + $0).font(.callout).fixedSize(horizontal: false, vertical: true) }
                    point("At its hardest:", lore.hardest + ".")
                    point("Body:", lore.body + ".")
                    Text("The lagna, not the Sun's sign, tells a person's type. Its traits follow from the symbol of the rashi and its ruler, the strength of grahas in its houses, the lagna lord's regard for the other house lords, and which houses each graha rules. They describe a leaning; the lagna lord's own state decides how it shows.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 420, alignment: .leading)
                VStack(alignment: .leading, spacing: 1) {
                    Text("The lagna lord and the other lords").font(.headline).padding(.bottom, 4)
                    SheetRow(graha: nil, cells: zip(["House", "Lord", "\(name) holds it as", "And what joins"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                    ForEach(2...12, id: \.self) { house in
                        let other = chart.lord(ofHouse: house), regard = other == code ? nil : Lore.natural[code]?[other]
                        SheetRow(graha: other, cells: [
                            SheetCell(text: Chart.ordinal(house), width: widths[0]),
                            SheetCell(text: Names.lords[other] ?? other, width: widths[1], tint: Tint.graha(other)),
                            SheetCell(text: other == code ? "itself" : word(regard), width: widths[2], met: other == code || (regard ?? 0) != 0, helps: other == code || (regard ?? 0) > 0),
                            SheetCell(text: other == code ? "self and \(Lore.houseNames[house - 1].lowercased()) are one concern" : (regard ?? 0) > 0 ? "drawn toward \(Lore.houseNames[house - 1].lowercased())" : (regard ?? 0) < 0 ? "adjustment is asked with \(Lore.houseNames[house - 1].lowercased())" : "even toward \(Lore.houseNames[house - 1].lowercased())", width: widths[3])])
                    }
                    Text("The Sun rules the \(chart.housesRuled(by: "Su").map(Chart.ordinal).joined()) house of this lagna, so the soul's light falls on \(Lore.houseNames[(chart.housesRuled(by: "Su").first ?? 1) - 1].lowercased()).")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 6)
                }
            }
        }
    }
}

/// The rules of house analysis applied to this chart: natural and temporal benefics and malefics, what each
/// house lord gives from where it stands, what steadies it, and which lords protect their own houses.
struct BhavaVicharaCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    private let widths: [CGFloat] = [70, 110, 190, 110, 330, 220]

    var body: some View {
        var marks: [Int: [ChartMark]] = [:]
        for house in 1...12 {
            let sign = chart.sign(ofHouse: house), label = [2, 11].contains(house) ? "(+)" : house == 3 ? "(−)" : Lore.positiveHouses.contains(house) ? "+" : "−"
            marks[sign] = [ChartMark(code: "p\(house)", label: label, sign: sign, note: "The \(Chart.ordinal(house)) house: " + (Lore.positiveHouses.contains(house) ? "a positive bhava" + ([2, 11].contains(house) ? ", sometimes counted neutral" : "") : house == 3 ? "a mild dusthana" : "a bhava that asks more"))]
                + chart.occupants(ofHouse: house).map { ChartMark(code: $0.id, label: $0.id) }
        }
        let seven = Array(chart.grahas.prefix(7)), fair = chart.grahas.filter { chart.benefic($0.id) }.map { Names.lords[$0.id] ?? $0.id }, harsh = chart.grahas.filter { !chart.benefic($0.id) }.map { Names.lords[$0.id] ?? $0.id }
        let moonNote = chart.moonWaxing == chart.moonBright ? "" : " The Moon is \(chart.moonWaxing ? "waxing yet still dark" : "waning yet still bright"): the textbook counts it by waxing and waning, the teaching line by its light, so here the two differ and it is read as borderline."
        return ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Positive bhavas and those that ask more").font(.headline)
                        ChartView(style: store.style, title: "", ascSign: chart.asc.sign, marks: marks).frame(width: 300, height: 300)
                        Text("Positive: 1, (2), 4, 5, 7, 9, 10, (11); the 2nd and 11th are sometimes counted neutral. Asking more: (3), 6, 8, 12; the 3rd is a mild dusthana.")
                            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 300, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Natural benefics and malefics").font(.headline)
                        Text("Natural benefics in this chart: \(fair.joined(separator: ", ")). They promote the desirable meanings of the bhavas they stand in and aspect, and of the karakas they join and aspect.")
                        Text("Natural malefics in this chart: \(harsh.joined(separator: ", ")). They bring forward the meanings that ask more, of the bhavas they stand in and aspect and of the karakas they join and aspect.")
                        Text("Jupiter, Venus, Mercury and a bright Moon are benefic by nature; Saturn, Rahu, Ketu, Mars, the Sun (called cruel more than malefic) and a dark Moon are malefic. Mercury stays a benefic unless malefics alone influence it.\(moonNote)").font(.caption).foregroundStyle(.secondary)
                        Text("Temporal benefics and malefics").font(.headline).padding(.top, 4)
                        Text("Each lagna gives the grahas a second nature by the houses they rule: lords of positive bhavas are temporal benefics, lords of bhavas that ask more are temporal malefics, whatever their own nature.")
                        Text("Karakas").font(.headline).padding(.top, 4)
                        Text("A karaka in a positive bhava promotes its desirable meanings; in a bhava that asks more, its harder ones; in an upachaya (3, 6, 10, 11) it improves steadily, after a hard start in the 3rd and 6th and a good one in the 10th and 11th.")
                    }
                    .font(.callout).fixedSize(horizontal: false, vertical: true).frame(width: 520, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 1) {
                    SheetRow(graha: nil, cells: zip(["Graha", "By nature", "By the houses it rules", "Stands in", "What it gives from there", "Stability"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                    ForEach(seven) { g in
                        let house = chart.house(ofSign: g.sign), t = chart.temporal(g.id)
                        SheetRow(graha: g.id, cells: [
                            SheetCell(text: Names.lords[g.id] ?? g.id, width: widths[0], tint: Tint.graha(g.id)),
                            SheetCell(text: chart.benefic(g.id) ? "natural benefic" : "natural malefic", width: widths[1], met: true, helps: chart.benefic(g.id)),
                            SheetCell(text: chart.temporalWord(g.id), width: widths[2], met: t.positive.isEmpty || t.negative.isEmpty, helps: t.negative.isEmpty),
                            SheetCell(text: "the \(Chart.ordinal(house)), \(Lore.positiveHouses.contains(house) ? "positive" : "asks more")", width: widths[3], met: true, helps: Lore.positiveHouses.contains(house)),
                            SheetCell(text: chart.temporalResult(g), width: widths[4]),
                            SheetCell(text: chart.stability(g), width: widths[5])])
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("The lord looks after its own house").font(.headline)
                    ForEach(chart.protectors, id: \.self) { Text($0).font(.callout) }
                    Text("A topic is read from three things together: the bhava, its lord and its karaka, for marriage the 7th, the 7th lord and Venus. As a rule of thumb the bhava carries 40 parts in a hundred, the lord 40 and the karaka 20, unless the karaka is itself tied to the bhava, when it weighs as much as they do. Each statement above is then qualified, layer by layer: by the graha's condition (the Strength desk), its natural leaning and role as karaka, the lord that protects its own, the yogas, and the lagna. Rahu and Ketu rule no house and so have no temporal nature.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 900, alignment: .leading).padding(.top, 4)
                }
            }
        }
    }
}
