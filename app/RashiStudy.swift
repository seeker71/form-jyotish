import SwiftUI

/// The twelve rashis as Light on Life classes them (chapter 5): how each rises, its element and the dosha, the
/// direction, the part of the body, fruitfulness, length and parity, with the house it is in this chart.
extension Lore {
    static let headRising: Set<Int> = [2, 4, 5, 6, 7, 10], backRising: Set<Int> = [0, 1, 3, 8, 9]
    static func rising(_ sign: Int) -> String { headRising.contains(sign) ? "head-rising (shirshodaya)" : backRising.contains(sign) ? "back-rising (prishthodaya)" : "rising both ways (ubhayodaya)" }
    static let signBody = ["the top and back of the head", "the face and throat", "the neck, shoulders, arms and hands", "the chest", "the upper abdomen, down to the navel", "the middle abdomen, below the navel",
                           "the lower abdomen", "the genitals and anus", "the thighs and hips", "the knees", "the calves", "the feet"]
    static let elementDosha = ["pitta", "vata", "mixed doshas", "kapha"], elementDirection = ["east", "south", "west", "north"]
    static func fruitful(_ sign: Int) -> String { sign % 4 == 3 ? "fruitful" : [0, 2, 4, 5].contains(sign) ? "barren" : "semi-fruitful" }
    /// yogas the app reads that Light on Life does not name
    static func yogaBeyondBook(_ name: String) -> Bool {
        ["Angaraka", "Gauri", "Kahala", "Shankha", "Shrapit", "Chatussagara", "Vasumati", "Visha", "Guru-Chandala", "Guru-Mangala", "Grahana", "Lagnadhi", "Maha-Lakshmi", "Su-shubha"].contains { name.hasPrefix($0) }
    }
    static func length(_ sign: Int) -> String { [0, 1, 10, 11].contains(sign) ? "short" : [4, 5, 6, 7].contains(sign) ? "long" : "average" }
}

struct RashiMeaningsCard: View {
    let chart: Chart
    private let widths: [CGFloat] = [118, 74, 150, 150, 150, 170, 120, 170]

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                SheetRow(graha: nil, cells: zip(["Rashi", "Lord", "Element, dosha, direction", "Quality and parity", "Rising", "Part of the body", "Fruitfulness, length", "In this chart"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                ForEach(0..<12, id: \.self) { sign in
                    let lord = Chart.signLords[sign], inside = chart.grahas.filter { $0.sign == sign }.map { Names.lords[$0.id] ?? $0.id }
                    SheetRow(graha: nil, sign: sign, cells: [
                        SheetCell(text: "\(sign + 1) · \(Names.signs[sign])\n\(Names.signsWestern[sign]), \(Lore.signSymbols[sign])", width: widths[0]),
                        SheetCell(text: Names.lords[lord] ?? lord, width: widths[1], tint: Tint.graha(lord)),
                        SheetCell(text: "\(Lore.elements[sign % 4].capitalized): \(Lore.elementDosha[sign % 4])\n\(Lore.elementDirection[sign % 4])", width: widths[2]),
                        SheetCell(text: "\(Lore.modes[sign % 3].capitalized)\n\(sign % 2 == 0 ? "odd, masculine" : "even, feminine")", width: widths[3]),
                        SheetCell(text: Lore.rising(sign), width: widths[4], met: Lore.headRising.contains(sign)),
                        SheetCell(text: Lore.signBody[sign].prefix(1).uppercased() + Lore.signBody[sign].dropFirst(), width: widths[5]),
                        SheetCell(text: "\(Lore.fruitful(sign).capitalized)\n\(Lore.length(sign))", width: widths[6]),
                        SheetCell(text: "The \(Chart.ordinal(chart.house(ofSign: sign))) house" + (sign == chart.asc.sign ? ", the lagna" : "") + "\n" + (inside.isEmpty ? "no graha" : inside.joined(separator: ", ")), width: widths[7], met: !inside.isEmpty)])
                }
                Text("The rashis are the star-fixed constellations, not the tropical signs of the same names. A rashi colours the graha in it; the graha matters more than the rashi. Head-rising rashis are read as auspicious and back-rising ones as asking more: a natural benefic in a head-rising rashi grows more benefic, a natural malefic in a back-rising one more malefic. The parts of the body are a full cross-section, so Karka covers the heart and lungs as well as the chest. Fruitfulness is read for children, length for stature. Click a row to open the sign.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 6)
            }
        }
    }
}
