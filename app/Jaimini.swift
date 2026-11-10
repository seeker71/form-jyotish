import SwiftUI

extension Lore {
    /// the seven chara karakas in order, each with what it stands for
    static let karakas: [(code: String, name: String, words: String)] = [
        ("AK", "Atmakaraka", "the self: the graha furthest through its sign, read as the chart's chief and the soul's own direction"),
        ("AmK", "Amatyakaraka", "the counsellor: work, vocation and those who advise"),
        ("BK", "Bhratrikaraka", "siblings and companions; in some teachings also the guru"),
        ("MK", "Matrikaraka", "the mother, nurture and the home"),
        ("PK", "Putrakaraka", "children, students and what one creates"),
        ("GK", "Gnatikaraka", "kin and rivals: where effort and skill are called for"),
        ("DK", "Darakaraka", "the partner: marriage and close alliance"),
    ]
}

/// The seven chara karakas: the grahas ranked by how far each has come through its sign.
struct KarakaCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    var body: some View {
        let j = chart.jaimini
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(j.karakas.enumerated()), id: \.offset) { index, code in
                let g = chart.graha(code), role = Lore.karakas[index]
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(role.code).fontWeight(.semibold).frame(width: 36, alignment: .leading)
                    Text(role.name).frame(width: 110, alignment: .leading)
                    Text(Names.lords[code] ?? code).fontWeight(.medium).foregroundStyle(Tint.graha(code)).frame(width: 66, alignment: .leading)
                    Text(g.map { Names.dms($0.deg) } ?? "").monospacedDigit().foregroundStyle(.secondary).frame(width: 78, alignment: .leading)
                    Text(role.words.prefix(1).uppercased() + role.words.dropFirst() + ".").foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2).padding(.horizontal, 6)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.accentColor.opacity(store.pick?.graha == code ? 0.2 : 0)))
                .contentShape(Rectangle())
                .onTapGesture { store.pick = .graha(code) }
            }
            HStack(spacing: 6) {
                Text("Karakamsa: the atmakaraka's navamsa sign is").foregroundStyle(.secondary)
                Button(Names.signs[j.karakamsa]) { store.pick = .sign(j.karakamsa) }.buttonStyle(.bordered).controlSize(.small)
                Text("the \(Chart.ordinal(chart.house(ofSign: j.karakamsa))) house of the birth chart.").foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }
}

/// The arudha padas: the image each house casts, as a table and as a chart.
struct ArudhaCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private func label(_ house: Int) -> String { house == 1 ? "AL" : house == 12 ? "UL" : "A\(house)" }

    var body: some View {
        let padas = chart.jaimini.arudhas
        var marks: [Int: [ChartMark]] = [chart.asc.sign: [ChartMark(code: "As", label: "As", sign: chart.asc.sign)]]
        for house in 1...12 { marks[padas[house - 1], default: []].append(ChartMark(code: label(house), label: label(house), sign: padas[house - 1])) }
        return HStack(alignment: .top, spacing: 18) {
            ChartView(style: store.style, title: "Pada", ascSign: chart.asc.sign, marks: marks).frame(width: 220, height: 220)
            VStack(alignment: .leading, spacing: 1) {
                ForEach(1...12, id: \.self) { house in
                    let sign = padas[house - 1]
                    HStack(spacing: 8) {
                        Text(label(house)).fontWeight(.semibold).frame(width: 30, alignment: .leading)
                        Text("\(Chart.ordinal(house)) · \(Lore.houseNames[house - 1])").lineLimit(1).frame(width: 112, alignment: .leading)
                        Text(Names.signs[sign]).frame(width: 76, alignment: .leading)
                        Text("the \(Chart.ordinal(chart.house(ofSign: sign))) house").foregroundStyle(.secondary).lineLimit(1).fixedSize()
                    }
                    .padding(.vertical, 1.5).padding(.horizontal, 6)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.accentColor.opacity(store.pick == .sign(sign) ? 0.2 : 0)))
                    .contentShape(Rectangle())
                    .onTapGesture { store.pick = .sign(sign) }
                }
                Text("AL, the arudha of the lagna, is how the person is seen. UL, the upapada, the arudha of the 12th, is read for marriage.")
                    .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).padding(.top, 4)
            }
        }
    }
}

/// The Chara dasha: periods of signs, each with twelve equal sub-periods.
struct CharaDashaCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    @State private var open: Set<String> = []

    var body: some View {
        let format = Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: store.zone)
        let day = store.viewDay ?? chart.jd, periods = chart.jaimini.chara
        VStack(alignment: .leading, spacing: 6) {
            Text("The signs take their turns \(chart.jaimini.forward ? "forward" : "backward") through the zodiac from the lagna. A sign's years are the count from it to its lord.")
                .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if let maha = periods.first(where: { $0.holds(day) }), let antar = maha.antar?.first(where: { $0.holds(day) }) {
                HStack(spacing: 6) {
                    Text("Running \(store.atBirth ? "at birth" : "at the moment under view"):").fontWeight(.medium)
                    Button(Names.signs[maha.sign]) { store.pick = .sign(maha.sign) }.buttonStyle(.bordered).controlSize(.small)
                    Text("–")
                    Button(Names.signs[antar.sign]) { store.pick = .sign(antar.sign) }.buttonStyle(.bordered).controlSize(.small)
                    Text("until \(Names.date(julianDay: antar.end).formatted(format))").foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                ForEach(periods) { maha in
                    HStack(spacing: 6) {
                        Button { if open.contains(maha.id) { open.remove(maha.id) } else { open.insert(maha.id) } } label: {
                            Image(systemName: open.contains(maha.id) ? "chevron.down" : "chevron.right").frame(width: 12)
                        }
                        .buttonStyle(.plain).accessibilityLabel("Show the sub-periods of \(Names.signs[maha.sign])")
                        Text("\(Names.signs[maha.sign]) (\(maha.years ?? 0)y)").frame(width: 150, alignment: .leading)
                        Text("the \(Chart.ordinal(chart.house(ofSign: maha.sign))) house").foregroundStyle(.secondary).frame(width: 110, alignment: .leading)
                        Text("\(Names.date(julianDay: maha.start).formatted(format)) – \(Names.date(julianDay: maha.end).formatted(format))").foregroundStyle(.secondary)
                    }
                    .fontWeight(maha.holds(day) ? .bold : .regular)
                    .padding(.vertical, 1).padding(.horizontal, 4)
                    .contentShape(Rectangle())
                    .onTapGesture { store.pick = .sign(maha.sign); store.go(to: maha.start + 0.001) }
                    .help("Go to the start of this period")
                    if open.contains(maha.id) {
                        ForEach(maha.antar ?? []) { antar in
                            HStack(spacing: 6) {
                                Text(Names.signs[antar.sign]).frame(width: 150, alignment: .leading)
                                Text("\(Names.date(julianDay: antar.start).formatted(format)) – \(Names.date(julianDay: antar.end).formatted(format))").foregroundStyle(.secondary)
                            }
                            .fontWeight(antar.holds(day) ? .bold : .regular)
                            .padding(.leading, 36)
                            .contentShape(Rectangle())
                            .onTapGesture { store.pick = .sign(antar.sign); store.go(to: antar.start + 0.001) }
                        }
                    }
                }
            }
            .monospacedDigit()
            Text("Read after K.N. Rao's method. In a sign's period the matters of the house it falls in, of the grahas in it and of the signs it aspects come forward.")
                .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Where the app's rules and wording come from, and how it speaks.
struct SourcesCard: View {
    private func source(_ title: String, _ words: String, _ link: String?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 6) {
                Text(title).fontWeight(.semibold)
                if let link, let url = URL(string: link) { Link("open", destination: url).font(.callout) }
            }
            Text(words).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How the app speaks").font(.subheadline).fontWeight(.semibold)
            Text("It states the conditions a chart shows and the understandings the tradition attaches to them, and it stops there. It names what supports a graha and what asks more of it side by side. A chart describes conditions; what is made of them remains with the person. Where the tradition's words are stern (dusthana, debilitated, malefic), the app keeps the word, so you can look it up anywhere, and gives the constructive reading the same teachers give: effort, depth, release, strength gained by use.")
                .fixedSize(horizontal: false, vertical: true)
            Text("Where the positions come from").font(.subheadline).fontWeight(.semibold).padding(.top, 2)
            source("NASA JPL DE440", "The planetary ephemeris every position is read from. The app's positions are checked against NASA's Horizons service and against Swiss Ephemeris, and agree within a fraction of an arcsecond.", "https://ssd.jpl.nasa.gov/horizons/")
            Text("Where the rules come from").font(.subheadline).fontWeight(.semibold).padding(.top, 2)
            source("Brihat Parashara Hora Shastra", "Houses and their lords, dignities, aspects, vargas, yogas, the dashas, ashtakavarga. The arudha pada rule follows its chapter on padas: a pada falling on its own house moves to the tenth from it, one falling on the seventh to the fourth.", "https://archive.org/download/BPHSEnglish/BPHS%20-%201%20RSanthanam.pdf")
            source("Parashara, verse by verse", "The chapters on padas and on the karakas, with translation.", "https://enjoylearningsanskrit.com/scriptures/parashara/chapter-29")
            source("B.V. Raman, Graha and Bhava Balas", "Shadbala, row by row.", nil)
            source("K.N. Rao, Jaimini's Chara Dasha", "The order and years of the Chara dasha.", nil)
            source("K.S. Krishnamurti, Krishnamurti Paddhati", "The KP ayanamsa, sub-lords and significators.", nil)
            Text("Where schools differ, the app follows one and says which. Rules are stated beside what they find, so a reader can check them.")
                .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The workspaces as a strip that scrolls when the window is narrow, so none is ever pushed out of sight.
struct WorkspaceTabs: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Store.workspaces, id: \.self) { name in
                    Button(name) { store.workspace = name }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .fontWeight(store.workspace == name ? .semibold : .regular)
                        .foregroundStyle(store.workspace == name ? Color.primary : Color.secondary)
                        .background(Capsule().fill(Color.accentColor.opacity(store.workspace == name ? 0.22 : 0)))
                        .contentShape(Capsule())
                        .help(Help.workspace(name))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
        }
    }
}
