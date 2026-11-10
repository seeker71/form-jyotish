import Foundation

/// The general understandings a reader brings to a chart: what each house, sign and nakshatra stands for.
/// Kept to what the tradition broadly agrees on; nothing here is a prediction.
enum Lore {
    /// what each house covers, 1 to 12
    static let houses = [
        "the self: body, vitality, character, how life is met",
        "resources: wealth, family, speech, food",
        "effort: courage, younger siblings, skills, short journeys",
        "home: mother, land, vehicles, inner peace",
        "creation: children, intelligence, learning, past merit",
        "service and repair: work, health routines, debts cleared, opponents met",
        "the other: marriage, partnership, trade",
        "depth and renewal: longevity, change, the hidden, shared resources",
        "fortune: dharma, father, teachers, long journeys",
        "action: career, standing, authority",
        "gains: income, elder siblings, friends, fulfilment",
        "release: giving, rest, retreat, distant places, liberation",
    ]
    static let houseNames = ["Self", "Resources", "Effort", "Home", "Creation", "Service", "The other", "Renewal", "Fortune", "Action", "Gains", "Release"]

    /// how the houses group: the groups a reader weighs before anything else
    static func houseKind(_ house: Int) -> String {
        switch house {
        case 1: return "an angle and a trine (kendra and trikona): the strongest place"
        case 4, 7, 10: return "an angle (kendra): grahas here act strongly"
        case 5, 9: return "a trine (trikona): the houses of fortune"
        case 6, 8, 12: return "a dusthana, a house of effort and release: what is met here builds capacity\(house == 6 ? ", and the 6th also grows with time (upachaya)" : house == 8 ? ", through depth and renewal" : ", through letting go")"
        case 3, 11: return "a growing house (upachaya): results improve with effort and time"
        default: return "a neutral house: neither angle nor trine"
        }
    }

    static let elements = ["fire", "earth", "air", "water"], modes = ["movable", "fixed", "dual"]
    static let signSymbols = ["the ram", "the bull", "the pair", "the crab", "the lion", "the maiden", "the scales", "the scorpion", "the archer", "the sea-creature", "the water-bearer", "the fishes"]
    static func sign(_ sign: Int) -> String {
        let quality = ["starts things", "holds things steady", "adapts and joins"][sign % 3]
        return "\(signSymbols[sign].capitalized): a \(modes[sign % 3]) \(elements[sign % 4]) sign, one that \(quality)."
    }

    /// each nakshatra's presiding deity and symbol
    static let nakshatras: [(deity: String, symbol: String)] = [
        ("the Ashwini Kumaras, physicians of the gods", "a horse's head"), ("Yama, lord of restraint", "the womb"), ("Agni, fire", "a blade or flame"),
        ("Brahma, the creator", "a cart"), ("Soma, the Moon", "a deer's head"), ("Rudra, the storm", "a teardrop"),
        ("Aditi, mother of the gods", "a quiver of arrows"), ("Brihaspati, teacher of the gods", "a flower, or a cow's udder"), ("the Nagas, serpents", "a coiled serpent"),
        ("the Pitris, the ancestors", "a throne"), ("Bhaga, giver of delight", "the front of a couch"), ("Aryaman, patron of bonds", "the back of a couch"),
        ("Savitar, the Sun as inspirer", "a hand"), ("Tvashtar, the divine craftsman", "a bright jewel"), ("Vayu, the wind", "a young shoot in the wind"),
        ("Indra and Agni together", "a triumphal arch"), ("Mitra, friendship", "a lotus"), ("Indra, chief of the gods", "an earring or umbrella"),
        ("Nirriti, dissolution", "a bundle of roots"), ("Apas, the waters", "a winnowing fan"), ("the Vishvedevas, the universal gods", "an elephant's tusk"),
        ("Vishnu, the preserver", "an ear, or three footprints"), ("the eight Vasus", "a drum"), ("Varuna, the cosmic waters", "an empty circle"),
        ("Aja Ekapada, the one-footed goat", "the front of a funeral cot"), ("Ahir Budhnya, serpent of the deep", "the back of a funeral cot"), ("Pushan, the nourisher", "a fish"),
    ]
    static func nakshatra(_ index: Int) -> String { "Presided over by \(nakshatras[index].deity); its sign is \(nakshatras[index].symbol)." }

    static let balance = "These are factors a reader weighs against each other; no single one decides a matter. A chart describes conditions. What is made of them remains with the person."
}

/// Facts read off a chart that the teaching views share: who rules which house, who sits where, and what
/// supports or strains a graha.
extension Chart {
    static let signLords = ["Ma", "Ve", "Me", "Mo", "Su", "Me", "Ve", "Ma", "Ju", "Sa", "Sa", "Ju"]

    func house(ofSign sign: Int) -> Int { (sign - asc.sign + 12) % 12 + 1 }
    func sign(ofHouse house: Int) -> Int { (asc.sign + house - 1) % 12 }
    func lord(ofHouse house: Int) -> String { Chart.signLords[sign(ofHouse: house)] }
    func housesRuled(by code: String) -> [Int] { (1...12).filter { lord(ofHouse: $0) == code } }
    func occupants(ofHouse house: Int) -> [Graha] { grahas.filter { $0.sign == sign(ofHouse: house) } }

    static func ordinal(_ n: Int) -> String { "\(n)" + (n == 1 ? "st" : n == 2 ? "nd" : n == 3 ? "rd" : "th") }

    /// What speaks for a graha and what against, stated as facts of this chart.
    func factors(for g: Graha) -> (supports: [String], strains: [String]) {
        var supports: [String] = [], strains: [String] = []
        let house = house(ofSign: g.sign), index = grahas.prefix(7).firstIndex { $0.id == g.id }
        switch g.status {
        case "Exalt.": supports.append("Exalted in \(Names.signs[g.sign])")
        case "Own": supports.append("In its own sign")
        case "Grt.Fr.": supports.append("In the sign of a great friend")
        case "Friend": supports.append("In a friend's sign")
        case "Debil.": strains.append("Debilitated in \(Names.signs[g.sign]): its gifts come through effort")
        case "Enemy": strains.append("In the sign of a graha it is at odds with")
        case "Grt.En.": strains.append("In the sign of a graha it is much at odds with")
        default: break
        }
        if [1, 4, 7, 10].contains(house) { supports.append("In an angle, the \(Chart.ordinal(house)) house") }
        else if [5, 9].contains(house) { supports.append("In a trine, the \(Chart.ordinal(house)) house") }
        else if [6, 8, 12].contains(house) { strains.append("In a dusthana, the \(Chart.ordinal(house)): it works through \(house == 6 ? "service and effort" : house == 8 ? "depth and renewal" : "release")") }
        if g.navamsa == g.sign { supports.append("Vargottama: the same sign in the navamsa") }
        if g.combust == true { strains.append("Combust: close to the Sun, working inwardly") }
        let seenBy = aspecting(sign: g.sign).filter { $0 != g.id }
        for code in seenBy where ["Ju", "Ve", "Me"].contains(code) { supports.append("Aspected by \(Names.lords[code] ?? code)") }
        for code in seenBy where ["Sa", "Ma"].contains(code) { strains.append("Aspected by \(Names.lords[code] ?? code): asks for \(code == "Sa" ? "patience and structure" : "courage and directness")") }
        for node in grahas.suffix(2) where node.sign == g.sign && node.id != g.id { strains.append("Shares its sign with \(node.name): \(node.id == "Ra" ? "amplified, unconventional" : "turned inward")") }
        if let index {
            let ratio = strengthRatio(index), bindus = ashtakavarga[index][g.sign]
            if ratio >= 1 { supports.append(String(format: "Shadbala %.2f times what is required", ratio)) } else { strains.append(String(format: "Shadbala %.2f of what is required", ratio)) }
            if bindus >= 5 { supports.append("\(bindus) of 8 bindus in its own ashtakavarga here") } else if bindus <= 2 { strains.append("Only \(bindus) of 8 bindus in its own ashtakavarga here") }
        }
        return (supports, strains)
    }
}
