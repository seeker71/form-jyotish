import SwiftUI

/// Ashtakoota: the eight measures by which two Moons are compared, 36 points in all.
/// The tables follow the open-source PyJHora (jhora/horoscope/match/compatibility.py), which follows the North
/// Indian almanacs; the varna of a sign follows its element. Almanacs differ on Vashya and Yoni by up to a point.
enum Match {
    /// what the comparison reads of one person: the Moon's sign, its longitude and its nakshatra
    struct Moon {
        var sign: Int
        var lon: Double
        var nak: Int
        var pada: Int
        init(sign: Int, lon: Double, nak: Int, pada: Int) { self.sign = sign; self.lon = lon; self.nak = nak; self.pada = pada }
        init?(_ chart: Chart) {
            guard let m = chart.graha("Mo") else { return nil }
            self.init(sign: m.sign, lon: m.lon, nak: m.nak, pada: m.pada)
        }
    }

    struct Koota: Identifiable {
        let name: String
        let looksAt: String
        let first: String
        let second: String
        let points: Double
        let of: Double
        let words: String
        var id: String { name }
    }

    static let varnas = ["Brahmin", "Kshatriya", "Vaishya", "Shudra"]
    static let varnaWords = ["knowledge and counsel", "protection and leading", "trade and making", "service and craft"]
    /// by the sign's element: water, fire, earth, air
    static func varna(_ sign: Int) -> Int { [1, 2, 3, 0][sign % 4] }

    static let vashyas = ["Chatushpada", "Manava", "Jalachara", "Vanachara", "Keeta"]
    static let vashyaWords = ["four-footed", "human", "of the water", "of the wild", "many-footed"]
    static func vashya(_ m: Moon) -> Int {
        let late = m.lon.truncatingRemainder(dividingBy: 30) >= 15
        switch m.sign {
        case 0, 1: return 0
        case 2, 5, 6, 10: return 1
        case 3, 11: return 2
        case 4: return 3
        case 7: return 4
        case 8: return late ? 0 : 1
        default: return late ? 2 : 0
        }
    }
    static let vashyaPoints: [[Double]] = [[2, 1, 1, 1.5, 1], [1, 2, 1.5, 0, 1], [1, 1.5, 2, 1, 1], [0, 0, 0, 2, 0], [1, 1, 1, 0, 2]]

    static let taras = ["Janma", "Sampat", "Vipat", "Kshema", "Pratyak", "Sadhaka", "Vadha", "Mitra", "Parama Mitra"]

    static let yonis = ["Horse", "Elephant", "Sheep", "Serpent", "Dog", "Cat", "Rat", "Cow", "Buffalo", "Tiger", "Deer", "Monkey", "Mongoose", "Lion"]
    static let yoniOf = [0, 1, 2, 3, 3, 4, 5, 2, 5, 6, 6, 7, 8, 9, 8, 9, 10, 10, 4, 11, 12, 11, 13, 0, 13, 7, 1]
    static let yoniPoints: [[Double]] = [
        [4, 2, 2, 3, 2, 2, 2, 1, 0, 1, 1, 3, 2, 1], [2, 4, 3, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0], [2, 3, 4, 2, 1, 2, 1, 3, 3, 1, 2, 0, 3, 1],
        [3, 3, 2, 4, 2, 1, 1, 1, 1, 2, 2, 2, 0, 2], [2, 2, 1, 2, 4, 2, 1, 2, 2, 1, 0, 2, 1, 1], [2, 2, 2, 1, 2, 4, 0, 2, 2, 1, 3, 3, 2, 1],
        [2, 2, 1, 1, 1, 0, 4, 2, 2, 2, 2, 2, 1, 2], [1, 2, 3, 1, 2, 2, 2, 4, 3, 0, 3, 2, 2, 1], [0, 3, 3, 1, 2, 2, 2, 3, 4, 1, 2, 2, 2, 1],
        [1, 1, 1, 2, 1, 1, 2, 0, 1, 4, 1, 1, 2, 1], [1, 2, 2, 2, 0, 3, 2, 3, 2, 1, 4, 2, 2, 1], [3, 3, 0, 2, 2, 3, 2, 2, 2, 1, 2, 4, 3, 2],
        [2, 2, 3, 0, 1, 2, 1, 2, 2, 2, 2, 3, 4, 2], [1, 0, 1, 2, 1, 1, 2, 1, 1, 1, 1, 2, 2, 4]]

    /// the lords in the order Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn
    static let lordOf = [2, 5, 3, 1, 0, 3, 5, 2, 4, 6, 6, 4]
    static let lordCodes = ["Su", "Mo", "Ma", "Me", "Ju", "Ve", "Sa"]
    static let maitriPoints: [[Double]] = [
        [5, 5, 5, 4, 5, 0, 0], [5, 5, 4, 1, 4, 0.5, 0.5], [5, 4, 5, 0.5, 5, 3, 0.5], [4, 1, 0.5, 5, 0.5, 5, 4],
        [5, 4, 5, 0.5, 5, 0.5, 3], [0, 0.5, 3, 5, 0.5, 5, 5], [0, 0.5, 0.5, 4, 3, 5, 5]]

    static let ganas = ["Deva", "Manushya", "Rakshasa"]
    static let ganaWords = ["gentle and giving", "worldly and practical", "forceful and independent"]
    static func gana(_ nak: Int) -> Int { [0, 4, 6, 7, 12, 14, 16, 21, 26].contains(nak) ? 0 : [1, 3, 5, 10, 11, 19, 20, 24, 25].contains(nak) ? 1 : 2 }
    /// rows: the one the count starts from (the bride of the tradition); columns: the other
    static let ganaPoints: [[Double]] = [[6, 6, 0], [5, 6, 0], [1, 0, 6]]

    static let nadis = ["Adi", "Madhya", "Antya"]
    static let nadiWords = ["vata, of air", "pitta, of fire", "kapha, of water"]
    static func nadi(_ nak: Int) -> Int { [0, 1, 2, 2, 1, 0][nak % 6] }

    /// The eight kootas, counted from `a` (the bride of the tradition) to `b` (the groom).
    static func kootas(from a: Moon, to b: Moon) -> [Koota] {
        var list: [Koota] = []
        let va = varna(a.sign), vb = varna(b.sign)
        list.append(Koota(name: "Varna", looksAt: "orientation of work", first: "\(varnas[va]): \(varnaWords[va])", second: "\(varnas[vb]): \(varnaWords[vb])",
                          points: vb <= va ? 1 : 0, of: 1,
                          words: vb <= va ? "The two orientations sit easily in the traditional order." : "The orientations differ in the traditional order: each one's way of working asks for the other's respect."))
        let sa = vashya(a), sb = vashya(b), sp = vashyaPoints[sa][sb]
        list.append(Koota(name: "Vashya", looksAt: "mutual pull", first: "\(vashyas[sa]), \(vashyaWords[sa])", second: "\(vashyas[sb]), \(vashyaWords[sb])", points: sp, of: 2,
                          words: sp >= 2 ? "The two are of one kind and draw toward each other naturally." : sp >= 1 ? "A workable pull between two different kinds." : "Little natural pull: closeness here is chosen and tended."))
        let there = (b.nak - a.nak + 27) % 27 % 9, back = (a.nak - b.nak + 27) % 27 % 9
        let tp = ([2, 4, 6].contains(there) ? 0 : 1.5) + ([2, 4, 6].contains(back) ? 0 : 1.5)
        list.append(Koota(name: "Tara", looksAt: "how each star falls from the other's", first: "second falls in \(taras[there])", second: "first falls in \(taras[back])", points: tp, of: 3,
                          words: tp >= 3 ? "Each one's star falls well from the other's: they support each other's wellbeing." : tp > 0 ? "One direction is supportive; the other asks for care with timing and health." : "Both directions ask for care: patience with each other's rhythms."))
        let ya = yoniOf[a.nak], yb = yoniOf[b.nak], yp = yoniPoints[ya][yb]
        list.append(Koota(name: "Yoni", looksAt: "instinct and intimacy", first: yonis[ya], second: yonis[yb], points: yp, of: 4,
                          words: yp >= 4 ? "The same nature: instinct meets instinct." : yp >= 3 ? "Friendly natures." : yp >= 2 ? "Neutral natures that learn each other." : "Natures the tradition sets apart: instinct differs, and understanding is built consciously."))
        let la = lordOf[a.sign], lb = lordOf[b.sign], mp = maitriPoints[la][lb]
        list.append(Koota(name: "Graha Maitri", looksAt: "friendship of the Moon-sign lords", first: Names.lords[lordCodes[la]] ?? "", second: Names.lords[lordCodes[lb]] ?? "", points: mp, of: 5,
                          words: mp >= 4 ? "The two minds are friends: outlook and values meet easily." : mp >= 3 ? "The two minds are neutral to each other." : "The lords are at odds by nature: outlooks differ, and each widens the other's view when heard."))
        let ga = gana(a.nak), gb = gana(b.nak), gp = ganaPoints[ga][gb]
        list.append(Koota(name: "Gana", looksAt: "temperament", first: "\(ganas[ga]): \(ganaWords[ga])", second: "\(ganas[gb]): \(ganaWords[gb])", points: gp, of: 6,
                          words: gp >= 5 ? "Temperaments that live together easily." : "Temperaments of different force: room for each one's pace keeps the peace."))
        let apart = (b.sign - a.sign + 12) % 12 + 1
        let bp: Double = [2, 12, 5, 9, 6, 8].contains(apart) ? 0 : 7
        let eased = bp == 0 && (la == lb || maitriPoints[la][lb] >= 5)
        list.append(Koota(name: "Bhakoot", looksAt: "the two Moon signs, counted from each other", first: Names.signs[a.sign], second: "\(Names.signs[b.sign]), \(Chart.ordinal(apart)) from the first", points: bp, of: 7,
                          words: bp > 0 ? "The Moon signs stand well from each other: feeling flows between them."
                                        : "The signs stand \(apart == 2 || apart == 12 ? "2nd and 12th" : apart == 5 || apart == 9 ? "5th and 9th" : "6th and 8th") from each other, a placing read as asking for attention to \(apart == 2 || apart == 12 ? "shared resources" : apart == 5 || apart == 9 ? "family and children" : "health and adjustment")." + (eased ? " Their lords are the same or friends, which many teachers hold to lift this." : "")))
        let na = nadi(a.nak), nb = nadi(b.nak), np: Double = na == nb ? 0 : 8
        let lifted = np == 0 && ((a.sign == b.sign && a.nak != b.nak) || (a.nak == b.nak && a.pada != b.pada) || (a.nak == b.nak && a.sign != b.sign))
        list.append(Koota(name: "Nadi", looksAt: "constitution", first: "\(nadis[na]): \(nadiWords[na])", second: "\(nadis[nb]): \(nadiWords[nb])", points: np, of: 8,
                          words: np > 0 ? "Different constitutions, which the tradition reads as complementing each other."
                                        : "The same constitution. The tradition reads this as asking for attention to health and vitality in the family line." + (lifted ? " Many teachers hold it lifted here, since the Moons share a sign or a star but not the same quarter." : "")))
        return list
    }

    /// A known pair, worked by hand: first Moon in Ashwini (Mesha), second in Rohini (Vrishabha) gives 23.5.
    static func check() -> Double {
        kootas(from: Moon(sign: 0, lon: 5, nak: 0, pada: 2), to: Moon(sign: 1, lon: 45, nak: 3, pada: 2)).reduce(0) { $0 + $1.points }
    }
}

/// Two charts compared by the eight kootas, with what each measure looks at.
struct MatchCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    @State private var otherID: Birth.ID? = nil
    @State private var other: Chart? = nil
    @State private var failure: String? = nil
    @State private var swapped = false

    private var others: [Birth] { store.births.filter { $0.id != store.current } }

    private func read() {
        guard let birth = others.first(where: { $0.id == otherID }) ?? others.first else { other = nil; return }
        let engine = store.engine, node = store.node, ayanamsa = store.ayanamsa, id = birth.id
        Task.detached {
            let result = Result { try engine.chart(for: birth, node: node, ayanamsa: ayanamsa) }
            await MainActor.run {
                guard id == (otherID ?? others.first?.id) else { return }
                switch result {
                case .success(let c): other = c; failure = nil
                case .failure(let e): other = nil; failure = e.localizedDescription
                }
            }
        }
    }

    private func kuja(_ c: Chart) -> Bool { c.yogas.contains { $0.name.hasPrefix("Kuja dosha") } }
    private func points(_ p: Double) -> String { p == p.rounded() ? String(Int(p)) : String(format: "%.1f", p) }

    var body: some View {
        let here = store.birth?.name ?? "This chart"
        VStack(alignment: .leading, spacing: 8) {
            if others.isEmpty {
                Text("A match compares two charts. Add a second chart with the + in the sidebar, and it appears here.").foregroundStyle(.secondary)
            } else {
                HStack(spacing: 10) {
                    Text(here).fontWeight(.semibold)
                    Text("with")
                    Picker("", selection: Binding(get: { otherID ?? others.first?.id }, set: { otherID = $0 })) {
                        ForEach(others) { Text($0.name).tag(Optional($0.id)) }
                    }
                    .labelsHidden().frame(maxWidth: 220)
                    Toggle("Count from the second chart", isOn: $swapped).toggleStyle(.checkbox)
                        .help("The tradition counts from the bride's Moon to the groom's. Three measures (Varna, Vashya, Gana) depend on the direction; tick this to count the other way.")
                }
            }
            if let failure { Text(failure).foregroundStyle(.red) }
            if let other, let mine = Match.Moon(chart), let theirs = Match.Moon(other) {
                let name = others.first(where: { $0.id == (otherID ?? others.first?.id) })?.name ?? "Second"
                let kootas = swapped ? Match.kootas(from: theirs, to: mine) : Match.kootas(from: mine, to: theirs)
                let total = kootas.reduce(0) { $0 + $1.points }
                Text("\(swapped ? name : here)'s Moon: \(Names.signs[(swapped ? theirs : mine).sign]), \(Glossary.nakshatraNames[(swapped ? theirs : mine).nak]).   \(swapped ? here : name)'s Moon: \(Names.signs[(swapped ? mine : theirs).sign]), \(Glossary.nakshatraNames[(swapped ? mine : theirs).nak]).")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(kootas) { k in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(k.name).fontWeight(.semibold)
                                Text(k.looksAt).font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(width: 150, alignment: .leading).help(Help.term(k.name) ?? "")
                            Text("\(points(k.points)) of \(points(k.of))").monospacedDigit().fontWeight(.medium)
                                .foregroundStyle(k.points >= k.of * 0.6 ? Color.green : k.points > 0 ? Color.primary : Color.orange).frame(width: 64, alignment: .leading)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(k.first)  ·  \(k.second)").font(.callout)
                                Text(k.words).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                Divider()
                Text("\(points(total)) of 36").font(.title3).fontWeight(.semibold)
                Text("The almanacs take 18 as the measure of an easy match. The count describes how readily two temperaments meet. It says nothing of the worth of a bond, or of what two people build with what they are given: a low measure names where attention is asked, and couples who give it grow by it.")
                    .fixedSize(horizontal: false, vertical: true)
                let both = [kuja(chart), kuja(other)]
                Text(both[0] && both[1] ? "Kuja dosha stands in both charts, which the tradition reads as balanced: two people of like drive."
                     : both[0] || both[1] ? "Kuja dosha stands in \(both[0] ? here : name)'s chart and not in the other. Read as a difference of drive: it asks for directness handled with care."
                     : "Neither chart holds Kuja dosha.")
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Text("Tables after the open-source PyJHora, which follows the North Indian almanacs; almanacs differ on Vashya and Yoni by up to a point. The kootas read the two Moons only. A full comparison also reads each chart whole: the seventh houses, Venus and Jupiter, and the running dashas. " + Lore.balance)
                    .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear { read() }
        .onChanged(of: otherID) { read() }
        .onChanged(of: store.current) { otherID = nil; read() }
        .onChanged(of: store.ayanamsa) { read() }
        .onChanged(of: store.births.count) { read() }
    }
}
