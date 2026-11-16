import SwiftUI

/// The twelve rashis as Light on Life classes them (chapter 5): how each rises, its element and the dosha, the
/// direction, the part of the body, fruitfulness, length and parity, with the house it is in this chart.
extension Lore {
    static let headRising: Set<Int> = [2, 4, 5, 6, 7, 10], backRising: Set<Int> = [0, 1, 3, 8, 9]
    static func rising(_ sign: Int) -> String { headRising.contains(sign) ? "head-rising (shirshodaya)" : backRising.contains(sign) ? "back-rising (prishthodaya)" : "rising both ways (ubhayodaya)" }
    static let signBody = ["the top and back of the head", "the face and throat", "the neck, shoulders, arms and hands", "the chest", "the upper abdomen, down to the navel", "the middle abdomen, below the navel",
                           "the lower abdomen", "the genitals and anus", "the thighs and hips", "the knees", "the calves", "the feet"]
    static let elementDosha = ["pitta", "vata", "mixed doshas", "kapha"], elementDirection = ["east", "south", "west", "north"]
    /// the order of society each element is given: fire the warrior, earth the merchant, air the worker, water the priest
    static let elementCaste = ["Kshatriya", "Vaishya", "Shudra", "Brahman"]
    static let modeGuna = ["rajas", "tamas", "sattva"], modeSanskrit = ["chara", "sthira", "dvisvabhava"], modeKingdom = ["mineral", "vegetable", "animal"]
    /// the kind of creature each rashi is: how it moves and whether it has a voice
    static let signCreature = ["bestial, four-footed", "bestial, four-footed", "human, two-footed, with a voice", "insect or crustacean, crawling, mute", "bestial, four-footed", "human, two-footed, with a voice",
                               "human, two-footed, with a voice", "insect or reptile, crawling, mute", "first half human, second half four-footed", "first half four-footed, second half crawling",
                               "human, two-footed, with a voice", "aquatic, crawling, mute"]
    /// the kind of place each rashi points to
    static let signPlace = ["forest or plateau; hilly, newly opened or heated places", "field or meadow; farmland, barns and storerooms", "village or bedroom; streets, schoolrooms, places of play",
                            "pond or well; rivers, kitchens, places with running water", "mountains or caves; forts, jungles, high and steep places", "watered and cultivated land; gardens, granaries, places of craft",
                            "busy town or marketplace; shops and public rooms", "hole or cavity; hidden, low and stagnant places", "villages and cities; temples, estates, high open ground",
                            "forest with much water; mines, peaks, neglected rooms", "village, or an unusual place; where research and instruments are kept", "watery places; seas and shores, retreats and places apart"]
    static func fruitful(_ sign: Int) -> String { sign % 4 == 3 ? "fruitful" : [0, 2, 4, 5].contains(sign) ? "barren" : "semi-fruitful" }
    /// yogas the app reads that Light on Life does not name
    static func yogaBeyondBook(_ name: String) -> Bool {
        ["Angaraka", "Gauri", "Kahala", "Shankha", "Shrapit", "Chatussagara", "Vasumati", "Visha", "Guru-Chandala", "Guru-Mangala", "Grahana", "Lagnadhi", "Maha-Lakshmi", "Su-shubha"].contains { name.hasPrefix($0) }
    }
    static func length(_ sign: Int) -> String { [0, 1, 10, 11].contains(sign) ? "short" : [4, 5, 6, 7].contains(sign) ? "long" : "medium" }
}

struct RashiMeaningsCard: View {
    let chart: Chart
    private let widths: [CGFloat] = [118, 70, 140, 150, 130, 150, 170, 210, 160]

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                SheetRow(graha: nil, cells: zip(["Rashi", "Lord", "Element, dosha,\ndirection, order", "Quality, guna,\nparity, temper", "Rising, length", "Part of the body", "Fruitfulness, kingdom,\ncreature", "Place", "In this chart"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                ForEach(0..<12, id: \.self) { sign in
                    let lord = Chart.signLords[sign], inside = chart.grahas.filter { $0.sign == sign }.map { Names.lords[$0.id] ?? $0.id }
                    SheetRow(graha: nil, sign: sign, cells: [
                        SheetCell(text: "\(sign + 1) · \(Names.signs[sign])\n\(Names.signsWestern[sign]), \(Lore.signSymbols[sign])", width: widths[0]),
                        SheetCell(text: Names.lords[lord] ?? lord, width: widths[1], tint: Tint.graha(lord)),
                        SheetCell(text: "\(Lore.elements[sign % 4].capitalized): \(Lore.elementDosha[sign % 4])\n\(Lore.elementDirection[sign % 4]), \(Lore.elementCaste[sign % 4])", width: widths[2]),
                        SheetCell(text: "\(Lore.modes[sign % 3].capitalized) (\(Lore.modeSanskrit[sign % 3])), \(Lore.modeGuna[sign % 3])\n\(sign % 2 == 0 ? "odd, masculine, hard" : "even, feminine, gentle")", width: widths[3]),
                        SheetCell(text: Lore.rising(sign) + "\n" + Lore.length(sign), width: widths[4], met: Lore.headRising.contains(sign)),
                        SheetCell(text: Lore.signBody[sign].prefix(1).uppercased() + Lore.signBody[sign].dropFirst(), width: widths[5]),
                        SheetCell(text: "\(Lore.fruitful(sign).capitalized); \(Lore.modeKingdom[sign % 3])\n\(Lore.signCreature[sign])", width: widths[6]),
                        SheetCell(text: Lore.signPlace[sign].prefix(1).uppercased() + Lore.signPlace[sign].dropFirst(), width: widths[7]),
                        SheetCell(text: "The \(Chart.ordinal(chart.house(ofSign: sign))) house" + (sign == chart.asc.sign ? ", the lagna" : "") + "\n" + (inside.isEmpty ? "no graha" : inside.joined(separator: ", ")), width: widths[8], met: !inside.isEmpty)])
                }
                Text("The rashis are the star-fixed constellations, not the tropical signs of the same names. A rashi colours the graha in it; the graha matters more than the rashi. Head-rising rashis are read as auspicious and back-rising ones as asking more: a natural benefic in a head-rising rashi grows more benefic, a natural malefic in a back-rising one more malefic. Odd rashis are called masculine and hard, even ones feminine and gentle; these are archetypes, not genders. The parts of the body are a full cross-section, so Karka covers the heart and lungs as well as the chest. Fruitfulness is read for children, length for stature, the place for where a matter is found. Click a row to open the sign.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: 900, alignment: .leading).padding(.top, 6)
            }
        }
    }
}
