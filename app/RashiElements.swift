import SwiftUI

/// The two building blocks of a rashi, its element and its quality (guna), drawn on this chart's lagna and
/// counted for this chart; the twenty-seven nakshatras; and how the chart itself is laid out and read.
extension Lore {
    /// the four elements of the rashis and space: what each does, what its excess brings, the experience it is
    /// the key to, where it tends, and its shape
    static let elementLore: [(name: String, sanskrit: String, does: String, excess: String, key: String, tends: String, shape: String)] = [
        ("Fire", "agni", "transforms, spreads and reshapes", "tearing down and extremes", "spiritual", "to rise", "a triangle"),
        ("Earth", "prithvi", "gives structure and makes things real", "rigidity and lost mobility", "physical", "to move downward", "a square"),
        ("Air", "vayu", "circulates and learns", "flightiness and opinion", "mental", "to expand", "a hexagon"),
        ("Water", "jala", "takes in and nurtures", "over-sensitivity and losing oneself", "emotional", "to find its level", "a crescent"),
    ]
    /// the three qualities: what each is, and how a person strong in it tends to live
    static let gunaLore: [(mode: String, sanskrit: String, guna: String, power: String, people: String)] = [
        ("Movable", "chara", "rajas", "the power that projects: activity is its nature, and from it come desire, attachment and the stirrings of the mind", "active, fond of change, movement and travel, direct in approach; on the go outwardly, inwardly or both"),
        ("Fixed", "sthira", "tamas", "the power that veils: steadiness and inertia, which can make things seem other than they are", "steady, slow to change, fond of staying put, taking time to act and holding fixed views; hard to move, for better or worse"),
        ("Dual", "dvisvabhava", "sattva", "clarity: when it is unmixed the mind works steadily, with no veiling and no agitation", "fond of learning and thinking, drawn two ways over where to live, whom to be with and what work to do; versatile and many-talented, undecided when the choices are many"),
    ]
    static let nakshatraNames = ["Ashvini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni", "Uttara Phalguni", "Hasta", "Chitra", "Swati", "Vishakha",
                                 "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha", "Uttara Ashadha", "Shravana", "Dhanishtha", "Shatabhisha", "Purva Bhadrapada", "Uttara Bhadrapada", "Revati"]
    static let nakshatraMeanings = ["the horsemen", "the bearer", "the cutter", "the red, growing one", "the deer's head", "the moist one", "the return of the light", "the nourisher", "the embrace", "the mighty",
                                    "the former red one", "the latter red one", "the hand", "the bright one", "the independent one", "the forked one", "the follower of Radha", "the eldest", "the root",
                                    "the former unconquered", "the latter unconquered", "the ear", "the wealthiest", "the hundred physicians", "the former blessed feet", "the latter blessed feet", "the wealthy"]
    static let nakshatraLords = ["Ke", "Ve", "Su", "Mo", "Ma", "Ra", "Ju", "Sa", "Me"]
}

extension Chart {
    func grahas(inElement element: Int) -> [Graha] { grahas.filter { $0.sign % 4 == element } }
    func grahas(inMode mode: Int) -> [Graha] { grahas.filter { $0.sign % 3 == mode } }
}

/// Elements and gunas: two charts on this lagna with the chart's grahas in them, what each element and quality
/// is, and how this chart is weighted.
struct RashiElementsCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private func marks(_ label: (Int) -> String, _ note: (Int) -> String) -> [Int: [ChartMark]] {
        var marks: [Int: [ChartMark]] = [:]
        for sign in 0..<12 { marks[sign] = [ChartMark(code: "e\(sign)", label: label(sign), sign: sign, note: "\(Names.signs[sign]): \(note(sign))")] }
        for g in chart.grahas { marks[g.sign, default: []].append(ChartMark(code: g.id, label: g.id, retro: g.retro && Lore.five.contains(g.id))) }
        return marks
    }
    private func names(_ list: [Graha]) -> String { list.isEmpty ? "none" : "\(list.count): " + list.map { Names.lords[$0.id] ?? $0.id }.joined(separator: ", ") }

    var body: some View {
        let lagna = chart.asc.sign, lord = chart.graha(chart.lord(ofHouse: 1))
        let sameMode = lord.map { $0.sign % 3 == lagna % 3 } ?? false, sameElement = lord.map { $0.sign % 4 == lagna % 4 } ?? false
        let elementTop = (0..<4).map { chart.grahas(inElement: $0).count }.max() ?? 0, modeTop = (0..<3).map { chart.grahas(inMode: $0).count }.max() ?? 0
        let wide: [CGFloat] = [130, 190, 170, 110, 150, 230], gunas: [CGFloat] = [150, 300, 300, 230]
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rashis and elements").font(.headline)
                        ChartView(style: store.style, title: "", ascSign: lagna, marks: marks({ Lore.elements[$0 % 4].capitalized }, { "a \(Lore.elements[$0 % 4]) rashi" })).frame(width: 300, height: 300)
                        Text("Fire in 1, 5, 9 of the zodiac; earth in 2, 6, 10; air in 3, 7, 11; water in 4, 8, 12. Rashis of one element stand in trine to each other.")
                            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 300, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rashis and gunas").font(.headline)
                        ChartView(style: store.style, title: "", ascSign: lagna, marks: marks({ $0 % 3 == 2 ? "Dvisva-\nbhava" : Lore.modeSanskrit[$0 % 3].capitalized }, { "a \(Lore.modes[$0 % 3]) rashi, of \(Lore.modeGuna[$0 % 3])" })).frame(width: 300, height: 300)
                        Text("Chara (movable, rajas) in 1, 4, 7, 10; sthira (fixed, tamas) in 2, 5, 8, 11; dvisvabhava (dual, sattva) in 3, 6, 9, 12. Rashis of one quality stand in angles to each other.")
                            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 300, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This chart").font(.headline)
                        Text("The lagna is \(Names.signs[lagna]): \(Lore.elements[lagna % 4]), \(Lore.modes[lagna % 3]) (\(Lore.modeSanskrit[lagna % 3])).")
                        if let lord {
                            Text("Its lord \(Names.lords[lord.id] ?? lord.id) stands in \(Names.signs[lord.sign]): \(Lore.elements[lord.sign % 4]), \(Lore.modes[lord.sign % 3]).")
                            Text(sameMode ? "Lagna and lagna lord share the \(Lore.modes[lagna % 3]) quality, so that quality comes through strongly in the person." : "Lagna and lagna lord stand in different qualities, so neither quality alone marks the person.")
                                .fontWeight(sameMode ? .semibold : .regular)
                            if sameElement { Text("They share the \(Lore.elements[lagna % 4]) element as well.").fontWeight(.semibold) }
                        }
                        Text("Space (akasha), the fifth element, runs through the other four and gives them room to act; it has no rashi of its own. Its shape is a point, and the joints between rashis belong to it.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .font(.callout).fixedSize(horizontal: false, vertical: true).frame(width: 300, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 1) {
                    SheetRow(graha: nil, cells: zip(["Element", "What it does", "In excess", "Key to", "Tends", "Grahas of this chart in it"], wide).map { SheetCell(text: $0, width: $1, header: true) })
                    ForEach(0..<4, id: \.self) { index in
                        let e = Lore.elementLore[index], inside = chart.grahas(inElement: index)
                        SheetRow(graha: nil, cells: [
                            SheetCell(text: "\(e.name) (\(e.sanskrit))\nshape: \(e.shape)", width: wide[0]),
                            SheetCell(text: e.does.prefix(1).uppercased() + e.does.dropFirst(), width: wide[1]), SheetCell(text: e.excess.prefix(1).uppercased() + e.excess.dropFirst(), width: wide[2]),
                            SheetCell(text: "\(e.key) experience", width: wide[3]), SheetCell(text: e.tends, width: wide[4]),
                            SheetCell(text: names(inside), width: wide[5], met: inside.count == elementTop && elementTop > 0)])
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    SheetRow(graha: nil, cells: zip(["Quality", "Its power", "People strong in it", "Grahas of this chart in it"], gunas).map { SheetCell(text: $0, width: $1, header: true) })
                    ForEach(0..<3, id: \.self) { index in
                        let g = Lore.gunaLore[index], inside = chart.grahas(inMode: index)
                        SheetRow(graha: nil, cells: [
                            SheetCell(text: "\(g.mode) (\(g.sanskrit))\n\(g.guna)", width: gunas[0]),
                            SheetCell(text: g.power.prefix(1).uppercased() + g.power.dropFirst(), width: gunas[1]), SheetCell(text: g.people.prefix(1).uppercased() + g.people.dropFirst(), width: gunas[2]),
                            SheetCell(text: names(inside), width: gunas[3], met: inside.count == modeTop && modeTop > 0)])
                    }
                    Text("Element and quality are the two building blocks of a rashi; the other classes refine them. A lit cell marks where most of this chart's grahas stand.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 900, alignment: .leading).padding(.top, 6)
                }
            }
        }
    }
}

/// The twenty-seven nakshatras: name and meaning, span, ruler, deity, symbol, and what of this chart stands in each.
struct NakshatraCard: View {
    let chart: Chart
    private let widths: [CGFloat] = [150, 118, 66, 200, 160, 128, 170]

    private func span(_ index: Int) -> String {
        let place = { (lon: Double) -> String in
            let sign = Int(lon / 30) % 12, deg = lon - Double(Int(lon / 30)) * 30
            return String(format: "%02d°%02d′ \(Names.signsWestern[sign])", Int(deg + 0.001), Int(((deg + 0.001) - Double(Int(deg + 0.001))) * 60))
        }
        let from = Double(index) * 40 / 3, to = Double(index + 1) * 40 / 3
        return place(from) + "\n" + (index == 26 ? "30°00′ Pisces" : to.truncatingRemainder(dividingBy: 30) < 0.01 ? "30°00′ \(Names.signsWestern[Int(from / 30)])" : place(to))
    }

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                SheetRow(graha: nil, cells: zip(["Nakshatra", "From, to", "Ruler", "Deity", "Symbol", "Class", "In this chart"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                ForEach(0..<27, id: \.self) { index in
                    let lord = Lore.nakshatraLords[index % 9], inside = (chart.asc.nak == index ? ["Lagna"] : []) + chart.grahas.filter { $0.nak == index }.map { "\(Names.lords[$0.id] ?? $0.id) (pada \($0.pada))" }
                    let kind = Lore.nakClasses.first { $0.members.contains(index) }?.name ?? ""
                    SheetRow(graha: nil, cells: [
                        SheetCell(text: "\(index + 1) · \(Lore.nakshatraNames[index])\n\(Lore.nakshatraMeanings[index])", width: widths[0]),
                        SheetCell(text: span(index), width: widths[1]),
                        SheetCell(text: Names.lords[lord] ?? lord, width: widths[2], tint: Tint.graha(lord)),
                        SheetCell(text: Lore.nakshatras[index].deity.prefix(1).uppercased() + Lore.nakshatras[index].deity.dropFirst(), width: widths[3]),
                        SheetCell(text: Lore.nakshatras[index].symbol.prefix(1).uppercased() + Lore.nakshatras[index].symbol.dropFirst(), width: widths[4]),
                        SheetCell(text: kind, width: widths[5]),
                        SheetCell(text: inside.isEmpty ? "·" : inside.joined(separator: "\n"), width: widths[6], met: !inside.isEmpty)])
                }
                Text("The nakshatras are the Moon's twenty-seven mansions, each 13°20′ of the zodiac in four padas of 3°20′, so every rashi holds two and a quarter of them. Each of the nine grahas rules three, in the order of the Vimshottari dasha; a twenty-eighth, Abhijit, is counted for some purposes. The rashi describes the ground a graha stands on and how it acts outwardly; the nakshatra describes what moves it from within. A lit cell marks a nakshatra that holds the lagna or a graha of this chart; the Moon's nakshatra is the birth star and sets the first dasha.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 900, alignment: .leading).padding(.top, 6)
            }
        }
    }
}

/// How the birth chart is laid out and read, shown on this chart in both of its drawings.
struct ChartAnatomyCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private var marks: [Int: [ChartMark]] {
        var marks: [Int: [ChartMark]] = [chart.asc.sign: [ChartMark(code: "As", label: "As")]]
        for g in chart.grahas { marks[g.sign, default: []].append(ChartMark(code: g.id, label: g.id, retro: g.retro && Lore.five.contains(g.id))) }
        return marks
    }
    private func point(_ head: String, _ words: String) -> some View {
        (Text(head + ". ").fontWeight(.semibold) + Text(words)).font(.callout).fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        let lagna = chart.asc.sign, sixth = chart.sign(ofHouse: 6), lord = chart.lord(ofHouse: 1)
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("North Indian").font(.headline)
                    ChartView(style: .north, title: "", ascSign: lagna, marks: marks).frame(width: 300, height: 300)
                    Text("The bhavas keep their places and the rashis turn. The top centre diamond is always the 1st bhava; the bhavas are counted counter-clockwise from it. The number in each bhava is the rashi that falls there.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 300, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("South Indian").font(.headline)
                    ChartView(style: .south, title: "", ascSign: lagna, marks: marks).frame(width: 300, height: 300)
                    Text("The rashis keep their places, Meena at the top left, and run clockwise. The lagna is marked with a stroke and \"As\"; the bhavas are counted clockwise from it.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 300, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 9) {
                    Text("Anatomy of the lagna kundali").font(.headline)
                    point("The lagna", "the rashi rising on the eastern horizon at the time and place of birth. It is always the 1st bhava. Here \(Names.signs[lagna]) (\(Names.signsWestern[lagna])) rises, rashi number \(lagna + 1), and its lord is \(Names.lords[lord] ?? lord).")
                    point("Rashi numbers are not bhava numbers", "the 6th bhava of this chart holds rashi \(sixth + 1), \(Names.signs[sixth]) (\(Names.signsWestern[sixth])). Each rashi has a ruler, and that ruler is the lord of the bhava the rashi falls in.")
                    point("The nine grahas", "Su Sun, Mo Moon, Ma Mars, Me Mercury, Ju Jupiter, Ve Venus, Sa Saturn, Ra Rahu, Ke Ketu. A graha stands in a rashi and so in a bhava.")
                    point("Direction", "the bhavas are counted in the order the grahas move through the zodiac in transit. Rahu and Ketu alone always move the other way.")
                    point("Rashi and nakshatra", "the rashi is the province a graha stands in; the nakshatra is the place within that province. The rashi shows how it acts outwardly, the nakshatra what moves it within.")
                    Text("The app draws every chart in the style chosen in Settings; both are the same chart.").font(.caption).foregroundStyle(.secondary)
                }
                .frame(width: 380, alignment: .leading)
            }
        }
    }
}
