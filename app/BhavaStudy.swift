import SwiftUI

/// The houses and the grahas as a student learns them from Light on Life (chapters 4 and 6): how the houses are
/// classed, the four aims of life as four trines, every significator of each house, what each house and each
/// graha stands for, and where all of it falls in this chart.
extension Lore {
    static let houseSanskrit = ["Tanu", "Dhana", "Bhratri", "Sukha", "Putra", "Shatru", "Kalatra", "Mrityu", "Bhagya", "Karma", "Labha", "Vyaya"]

    /// every graha with a natural affinity for a house, with the matter it stands for there
    static let houseKarakas: [[(code: String, matter: String)]] = [
        [("Su", "health, vitality and the sense of self")],
        [("Ju", "wealth, family and speech")],
        [("Ma", "siblings, courage and enterprise")],
        [("Mo", "the mother and the feelings"), ("Ve", "vehicles and comforts"), ("Me", "education"), ("Ma", "land and property")],
        [("Ju", "children, counsel, discernment and past merit")],
        [("Ma", "acute illness, injury and litigation"), ("Sa", "debt and lasting illness")],
        [("Ve", "marriage, relationship and desire")],
        [("Sa", "longevity, legacies, upheaval and chronic illness")],
        [("Ju", "teachers, higher learning and fortune"), ("Su", "the father and the spirit")],
        [("Me", "commerce"), ("Su", "government, authority and fame"), ("Sa", "employment and industry"), ("Ju", "the professions")],
        [("Ju", "elder siblings, friends and gains")],
        [("Sa", "solitude, loss and foreign lands")],
    ]

    /// the four aims of life, each a trine of houses
    static let aimsOfLife: [(name: String, words: String, houses: [Int])] = [
        ("Dharma", "purpose, ethics and right action", [1, 5, 9]), ("Artha", "security, means and livelihood", [2, 6, 10]),
        ("Kama", "enjoyment, desire and relationship", [3, 7, 11]), ("Moksha", "release and inner freedom", [4, 8, 12])]
    static func aim(of house: Int) -> String { aimsOfLife[(house - 1) % 4].name }

    /// the classes a house belongs to, each with what the class means
    static func houseClasses(_ house: Int) -> [(name: String, words: String)] {
        var list: [(String, String)] = []
        if [1, 4, 7, 10].contains(house) { list.append(("Kendra", "an angle, a place of action where grahas act strongly")) }
        if [1, 5, 9].contains(house) { list.append(("Trikona", "a trine, a place of merit and opportunity")) }
        if [6, 8, 12].contains(house) { list.append(("Trik", "one of the three places of difficulty, where capacity is built through effort" + (house == 8 ? ", depth and renewal" : house == 12 ? " and letting go" : ""))) }
        if house == 3 { list.append(("Dusthana", "a place of difficulty, the mildest of the four (3, 6, 8, 12)")) }
        if [2, 7].contains(house) { list.append(("Maraka", "a place that bears on the close of the life span")) }
        if [3, 6, 10, 11].contains(house) { list.append(("Upachaya", "a place of improvement: results " + (house < 10 ? "start slowly and ease with time" : "are good and grow with time"))) }
        if [2, 5, 8, 11].contains(house) { list.append(("Panaphara", "a house that follows an angle")) }
        if [3, 6, 9, 12].contains(house) { list.append(("Apoklima", "a house falling away from an angle")) }
        return list
    }
    static func houseClassLine(_ house: Int) -> String {
        let article = ["Kendra": "a kendra", "Trikona": "a trikona", "Trik": "a trik-sthana", "Dusthana": "a dusthana", "Maraka": "a maraka-sthana", "Upachaya": "an upachaya", "Panaphara": "a panaphara", "Apoklima": "an apoklima"]
        let classes = houseClasses(house).map { "\(article[$0.name] ?? $0.name) (\($0.words))" }
        let aim = aimsOfLife[(house - 1) % 4]
        let leaning: String = [1, 4, 5, 7, 9, 10].contains(house) ? "It is counted among the positive houses" : [2, 11].contains(house) ? "It is counted positive, and sometimes neutral" : house == 3 ? "It is counted mildly among the houses that ask more" : "It is counted among the houses that ask more"
        let list: String = classes.joined(separator: "; ")
        let purpose: String = ". It is a house of " + aim.name.lowercased() + ": " + aim.words + ". "
        return list + purpose + leaning
    }

    /// what each house stands for, by theme
    static let houseMatters: [[(head: String, words: String)]] = [
        [("Body", "constitution, the birthplace, length of life"), ("Health", "vigour, illness and recovery"), ("Character", "temperament, happiness or sorrow, virtue"), ("Appearance", "build and complexion"), ("Standing", "dignity, honour and position"), ("Birth", "the start of life and youth")],
        [("Family", "the household and those one maintains"), ("Wealth", "savings and movable possessions"), ("Mouth", "food, speech and the voice"), ("Face", "the face, the right eye, the throat"), ("Learning", "what is learned early and by ear")],
        [("Siblings", "the younger ones; neighbours"), ("Courage", "prowess, the arms and hands"), ("Communication", "writing, messages, practical learning"), ("Arts and skills", "drawing, crafts and trades"), ("Short journeys", "quick travel and errands")],
        [("Mother", "the maternal line and the ancestors"), ("Home and land", "houses, fixed property, fields and wells"), ("Education", "schooling up to a degree"), ("Mind (manas)", "feelings, lasting happiness, memory"), ("Vehicles", "all conveyances"), ("Roots", "first values, one's community")],
        [("Children", "children and grandchildren"), ("Creativity", "music, writing, performance"), ("Buddhi", "discernment, counsel, teaching and students"), ("Practice", "mantra, the chosen deity, spiritual effort"), ("Purva punya", "merit brought from before"), ("Speculation", "ventures taken on judgement")],
        [("Opponents", "disputes, lawsuits, theft"), ("Debt", "credit and loans"), ("Illness", "acute illness, injuries, anxieties"), ("Routines", "diet, exercise, daily upkeep"), ("Service", "employees, service work, competition")],
        [("Marriage", "the spouse and courtship"), ("Partners", "business partners and dealings with others"), ("Desire", "attraction and its conduct"), ("Trade", "independent business, the go-between"), ("Journeys", "travel abroad, a journey within a journey")],
        [("Longevity", "the length of life and its close"), ("Others' money", "inheritance, settlements, a partner's wealth"), ("Hidden knowledge", "Jyotish, yoga, research, depth psychology, the occult"), ("Loss of means", "bankruptcy and reversals"), ("Chronic illness", "what is hard to cure"), ("Transformation", "crisis that opens a breakthrough")],
        [("Father", "the paternal line"), ("Higher knowledge", "wisdom and advanced study"), ("Bhagya", "fortune, affluence, good karma ripening"), ("Long journeys", "pilgrimage and travel far"), ("Religion", "the guru, devotion and worship"), ("Dharma", "innate ethics and opportunity")],
        [("Profession", "career, what one does in the world"), ("Authority", "government, leadership, large organisations"), ("Commerce", "trade and business"), ("Status", "fame, position and honours"), ("The sky", "what stands highest and is seen by all")],
        [("Gains", "wealth received"), ("Income", "what the career brings in"), ("Easy money", "investments and windfalls"), ("Elder siblings", "read apart from the 3rd"), ("Friends", "groups, societies and networks"), ("Hopes", "wishes and long-held goals")],
        [("Loss", "outlay of every kind"), ("Expenses", "of body, mind and spirit"), ("Foreign lands", "emigration and life far from home"), ("The bed", "sleep and its pleasures"), ("Seclusion", "hospitals, ashrams, retreats, confinement"), ("Moksha", "liberation and letting go")],
    ]
    static func matterLine(_ house: Int) -> String { "It stands for " + houseMatters[house - 1].map { "\($0.head.lowercased()) (\($0.words))" }.joined(separator: "; ") + "." }
    static func karakaLine(_ house: Int) -> String {
        "Its significator\(houseKarakas[house - 1].count > 1 ? "s" : ""): " + houseKarakas[house - 1].map { "\(Names.lords[$0.code] ?? $0.code) for \($0.matter)" }.joined(separator: "; ") + "."
    }

    /// what each graha stands for: its essence, the people, the matters, and its body and nature
    static let grahaMeanings: [String: (essence: String, people: String, matters: String, nature: String)] = [
        "Su": ("the soul (atma)", "the father, rulers, those in authority", "government, fame, vitality, the sense of self", "the heart, the head, the bones; pitta; hot and dry"),
        "Mo": ("the mind (manas)", "the mother, women, the public", "emotions, memory, perception, nourishment, beauty of face", "blood and the body's fluids, the chest; kapha and vata; white, cool and moist"),
        "Ma": ("energy in action", "siblings, soldiers, athletes, surgeons", "courage, land and property, contest, anger and pride", "the liver, muscle and marrow; pitta; red"),
        "Me": ("discerning intelligence", "students, traders, writers, friends", "education, communication, commerce, speech and writing, the rational mind", "the nervous system and the skin; all three doshas; versatile, neuter; green"),
        "Ju": ("wisdom", "teachers, advisors, children, the husband", "knowledge, fortune, spirituality, good counsel, growth and optimism", "fat and the liver; kapha; yellow"),
        "Ve": ("desire", "the spouse, women, artists", "marriage, sensuality, harmony, the fine arts, vehicles and comforts", "the reproductive system; kapha and vata; many-coloured"),
        "Sa": ("karma ripening through time", "elders, workers, renunciates", "longevity, sorrow and endurance, chronic illness, separation, solitude, discipline", "the legs and the nerves; vata; dark; cold and dry"),
        "Ra": ("worldly ambition", "foreigners and outsiders", "ambition, disguise, sudden events, attachment, intrigue, poisons", "acts like Saturn, and takes on the grahas joined to it and the lord of its sign"),
        "Ke": ("liberation", "ascetics and healers", "detachment, insight, suddenness, the occult, what is let go", "acts like Mars, and takes on the grahas joined to it and the lord of its sign"),
    ]
}

extension Chart {
    /// the grahas standing in the three houses of an aim
    func grahas(inAim index: Int) -> [Graha] { grahas.filter { Lore.aimsOfLife[index].houses.contains(house(ofSign: $0.sign)) } }

    /// where a graha stands and how, in a few words
    func placing(_ code: String) -> String {
        guard let g = graha(code) else { return "" }
        let state = g.status == "Exalt." ? ", exalted" : g.status == "Debil." ? ", debilitated" : g.status == "Own" ? ", in its own sign" : ""
        return "in the \(Chart.ordinal(house(ofSign: g.sign)))\(state)\(g.combust == true && g.id != "Mo" ? ", combust" : "")\(g.retro && Lore.five.contains(g.id) ? ", retrograde" : "")"
    }
}

/// Three charts on this lagna: angles and trines, the four aims with the chart's grahas in them, and the places of
/// difficulty, closing and improvement; then the four trines counted.
struct BhavaClassCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private func marks(_ pick: (Int) -> [(String, String)]) -> [Int: [ChartMark]] {
        var marks: [Int: [ChartMark]] = [:]
        for house in 1...12 {
            let sign = chart.sign(ofHouse: house)
            let classes = pick(house)
            marks[sign] = classes.isEmpty ? [] : [ChartMark(code: "c\(house)", label: classes.map(\.0).joined(separator: "\n"), sign: sign, note: "The \(Chart.ordinal(house)) house: " + classes.map(\.1).joined(separator: "; "))]
        }
        return marks
    }
    private var aimMarks: [Int: [ChartMark]] {
        var marks = marks { house in let aim = Lore.aimsOfLife[(house - 1) % 4]; return [(aim.name, "a house of \(aim.name.lowercased()), \(aim.words)")] }
        for g in chart.grahas { marks[g.sign, default: []].append(ChartMark(code: g.id, label: g.id, retro: g.retro && Lore.five.contains(g.id))) }
        return marks
    }
    private func panel(_ title: String, _ marks: [Int: [ChartMark]], _ words: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            ChartView(style: store.style, title: "", ascSign: chart.asc.sign, marks: marks).frame(width: 290, height: 290)
            Text(words).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 290, alignment: .leading)
        }
    }

    var body: some View {
        let counts = (0..<4).map { chart.grahas(inAim: $0).count }, top = counts.max() ?? 0
        let leading = (0..<4).filter { counts[$0] == top }.map { Lore.aimsOfLife[$0].name }
        let widths: [CGFloat] = [150, 190, 250, 280]
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 18) {
                    panel("The twelve bhavas", marks { h in [("\(h) \(Lore.houseSanskrit[h - 1])\n\(Lore.houseNames[h - 1])", Lore.houses[h - 1])] },
                          "The houses counted from this chart's lagna, each with its Sanskrit name. A bhava is a state or condition more than a place. Click a house to open it.")
                    panel("Angles and trines", marks { h in Lore.houseClasses(h).filter { ["Kendra", "Trikona"].contains($0.name) }.map { ($0.name, $0.words) } },
                          "The kendras (1, 4, 7, 10) are places of action; the trikonas (1, 5, 9) are places of merit and opportunity. Together they are the most valued houses; the 1st is both.")
                    panel("The four aims (purusharthas)", aimMarks,
                          "Dharma in 1, 5, 9; artha in 2, 6, 10; kama in 3, 7, 11; moksha in 4, 8, 12. Each aim is a trine of houses, with this chart's grahas set in them.")
                    panel("Difficulty, closing, improvement", marks { h in Lore.houseClasses(h).filter { ["Trik", "Dusthana", "Maraka", "Upachaya"].contains($0.name) }.map { ($0.name, $0.words) } },
                          "Trik-sthanas (6, 8, 12) and the 3rd are the dusthanas; the marakas are 2 and 7; the upachayas (3, 6, 10, 11) improve with time. The 12th from any house is read as the outlay of that house's matters.")
                }
                VStack(alignment: .leading, spacing: 1) {
                    SheetRow(graha: nil, cells: zip(["Aim", "Houses and signs", "Grahas in the trine", "Lords of its houses"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                    ForEach(0..<4, id: \.self) { index in
                        let aim = Lore.aimsOfLife[index], inside = chart.grahas(inAim: index)
                        SheetRow(graha: nil, cells: [
                            SheetCell(text: "\(aim.name): \(aim.words)", width: widths[0], met: counts[index] == top && top > 0),
                            SheetCell(text: aim.houses.map { "\(Chart.ordinal($0)) \(Names.signs[chart.sign(ofHouse: $0)])" }.joined(separator: "\n"), width: widths[1]),
                            SheetCell(text: inside.isEmpty ? "none" : "\(inside.count): " + inside.map { "\(Names.lords[$0.id] ?? $0.id) (\(Chart.ordinal(chart.house(ofSign: $0.sign))))" }.joined(separator: ", "), width: widths[2], met: counts[index] == top && top > 0),
                            SheetCell(text: aim.houses.map { "\(Chart.ordinal($0)): \(Names.lords[chart.lord(ofHouse: $0)] ?? "") \(chart.placing(chart.lord(ofHouse: $0)))" }.joined(separator: "\n"), width: widths[3])])
                    }
                    Text("Most of this chart's grahas stand in the houses of \(leading.joined(separator: " and ").lowercased()) (\(top) of \(chart.grahas.count)): that aim draws the most attention in the life. Each aim finds its fullest expression in its last house: dharma in the 9th, artha in the 10th, kama in the 11th, moksha in the 12th.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 6)
                }
            }
        }
    }
}

/// The significators of each house: a chart of them on this lagna, and where each one stands in this chart.
struct BhavaKarakaCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    var body: some View {
        var marks: [Int: [ChartMark]] = [:]
        for house in 1...12 {
            let sign = chart.sign(ofHouse: house)
            marks[sign] = Lore.houseKarakas[house - 1].map { ChartMark(code: $0.code, label: $0.code + (chart.graha($0.code)?.sign == sign ? " ✓" : "")) }
        }
        let widths: [CGFloat] = [130, 470]
        return ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    ChartView(style: store.style, title: "", ascSign: chart.asc.sign, marks: marks).frame(width: 290, height: 290)
                    Text("The karakas of each house, set on this lagna. A tick marks a karaka that stands in its own house here. A house is read by three limbs: the house, its lord and its karaka.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 290, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 1) {
                    SheetRow(graha: nil, cells: zip(["House", "Karakas, what each stands for, and where it stands here"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                    ForEach(1...12, id: \.self) { house in
                        SheetRow(graha: nil, sign: chart.sign(ofHouse: house), cells: [
                            SheetCell(text: "\(house) · \(Lore.houseSanskrit[house - 1])\n\(Lore.houseNames[house - 1])", width: widths[0], met: false),
                            SheetCell(text: Lore.houseKarakas[house - 1].map { "\(Names.lords[$0.code] ?? $0.code), \($0.matter): \(chart.placing($0.code))" }.joined(separator: "\n"), width: widths[1])])
                    }
                }
            }
        }
    }
}

/// What each house stands for, with its classes, its sign and its lord in this chart.
struct BhavaMeaningsCard: View {
    let chart: Chart
    private let widths: [CGFloat] = [120, 200, 520]

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                SheetRow(graha: nil, cells: zip(["House", "Classes, aim, and this chart", "What it stands for"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                ForEach(1...12, id: \.self) { house in
                    let sign = chart.sign(ofHouse: house), lord = chart.lord(ofHouse: house), inside = chart.occupants(ofHouse: house).map { Names.lords[$0.id] ?? $0.id }
                    SheetRow(graha: nil, sign: sign, cells: [
                        SheetCell(text: "\(house) · \(Lore.houseSanskrit[house - 1])\n\(Lore.houseNames[house - 1])", width: widths[0]),
                        SheetCell(text: (Lore.houseClasses(house).map(\.name) + [Lore.aim(of: house)]).joined(separator: ", ") + "\n\(Names.signs[sign]); lord \(Names.lords[lord] ?? lord) \(chart.placing(lord))\n" + (inside.isEmpty ? "No graha in it" : "In it: " + inside.joined(separator: ", ")), width: widths[1], met: !inside.isEmpty),
                        SheetCell(text: Lore.houseMatters[house - 1].map { "\($0.head): \($0.words)" }.joined(separator: "\n"), width: widths[2])])
                }
                Text("A bhava is a state or condition more than a place. A house's matters are read through the house, its lord and its karakas together; a lit cell marks a house with grahas standing in it. Click a row to open the house.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 6)
            }
        }
    }
}

/// What each graha stands for, and the part it plays in this chart.
struct GrahaMeaningsCard: View {
    let chart: Chart
    private let widths: [CGFloat] = [70, 120, 150, 210, 200, 220]

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                SheetRow(graha: nil, cells: zip(["Graha", "Essence", "People", "Matters", "Body and nature", "In this chart"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                ForEach(chart.grahas) { g in
                    if let m = Lore.grahaMeanings[g.id] {
                        let ruled = chart.housesRuled(by: g.id), signifies = (1...12).filter { h in Lore.houseKarakas[h - 1].contains { $0.code == g.id } }
                        let here = "Stands \(chart.placing(g.id)), in \(Names.signs[g.sign])" + (ruled.isEmpty ? "" : "\nRules the \(ruled.map(Chart.ordinal).joined(separator: " and "))") + (signifies.isEmpty ? "" : "\nKaraka of the \(signifies.map(Chart.ordinal).joined(separator: ", "))")
                        SheetRow(graha: g.id, cells: [
                            SheetCell(text: Names.lords[g.id] ?? g.id, width: widths[0], tint: Tint.graha(g.id)),
                            SheetCell(text: m.essence, width: widths[1]), SheetCell(text: m.people, width: widths[2]),
                            SheetCell(text: m.matters, width: widths[3]), SheetCell(text: m.nature, width: widths[4]),
                            SheetCell(text: here, width: widths[5], met: true)])
                    }
                }
                Text("A graha gives what it stands for by nature, coloured by the houses it rules and the house it stands in. How fully it gives is its strength; the Strength desk reads that.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 6)
            }
        }
    }
}
