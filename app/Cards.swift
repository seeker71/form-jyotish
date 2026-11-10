import SwiftUI

/// What can stand on a workspace. A card is named by an id; `chart:N` is the N-th varga.
struct CardInfo: Identifiable {
    let id: String
    let title: String
    /// words the command palette matches, beside the title
    let keywords: String
    /// a wide card takes the workspace's full width; narrow cards (the charts) sit in a grid
    let wide: Bool
}

enum Catalog {
    static let all: [CardInfo] =
        [CardInfo(id: "birth", title: "Birth data", keywords: "name date time place enter", wide: true)]
        + (0..<16).map { CardInfo(id: "chart:\($0)", title: $0 == 0 ? "Rasi chart" : "\(Names.vargaCodes[$0]) \(Names.vargas[$0])", keywords: "\(Names.vargaCodes[$0]) varga divisional chart", wide: false) }
        + [CardInfo(id: "match", title: "Match: two charts by the eight kootas", keywords: "relationship compatibility marriage guna milan ashtakoota kundli matching partner synastry koota", wide: true),
           CardInfo(id: "edges", title: "Near an edge", keywords: "boundary cusp sandhi gandanta sensitive birth time ayanamsa sign change junction", wide: true),
           CardInfo(id: "annual", title: "Annual chart (Varshaphal)", keywords: "varshaphal tajika solar return year muntha varsha birthday", wide: true),
           CardInfo(id: "sources", title: "Sources and voice", keywords: "references texts parashara raman rao method trust how", wide: true),
           CardInfo(id: "karakas", title: "Chara karakas", keywords: "jaimini atmakaraka amatyakaraka darakaraka karakamsa significators", wide: true),
           CardInfo(id: "arudhas", title: "Arudha padas", keywords: "jaimini pada arudha lagna upapada image", wide: true),
           CardInfo(id: "chara-dasha", title: "Chara dasha", keywords: "jaimini rasi sign dasha rao", wide: true),
           CardInfo(id: "glossary", title: "Glossary", keywords: "dictionary terms words meaning search look up what is", wide: true),
           CardInfo(id: "guide", title: "First steps: how a chart is read", keywords: "learn tutorial lesson teach help", wide: true),
           CardInfo(id: "reading", title: "This chart at a glance", keywords: "summary overview plain words", wide: true),
           CardInfo(id: "houses", title: "The twelve houses", keywords: "bhava lords areas of life", wide: true),
           CardInfo(id: "moon", title: "Chandra chart", keywords: "moon chandra lagna", wide: false),
           CardInfo(id: "grahas", title: "Grahas", keywords: "planets table positions nakshatra lords dignity", wide: true),
           CardInfo(id: "timeline", title: "Vimshottari timeline", keywords: "dasha graph periods zoom", wide: true),
           CardInfo(id: "dasha-context", title: "The running period in context", keywords: "dasha now current mahadasha antardasha lords meaning transit sade sati", wide: true),
           CardInfo(id: "other-dashas", title: "Other dasha systems", keywords: "ashtottari yogini shodashottari dwadashottari panchottari shatabdika chaturashiti dwisaptati shat-trimsha conditional", wide: true),
           CardInfo(id: "dashas", title: "Vimshottari periods", keywords: "dasha list mahadasha antardasha pratyantardasha sookshma", wide: true),
           CardInfo(id: "transit-dates", title: "Transit dates", keywords: "gochara ingress station retrograde sade sati exact dates events", wide: true),
           CardInfo(id: "shadbala", title: "Shadbala", keywords: "strength six-fold sthana dig kala cheshta naisargika drik rupas", wide: true),
           CardInfo(id: "ashtakavarga", title: "Ashtakavarga", keywords: "strength bindus bhinna sarva points", wide: true),
           CardInfo(id: "yogas", title: "Yogas", keywords: "combinations raja dhana dosha cancellation", wide: true),
           CardInfo(id: "aspects", title: "Aspects", keywords: "drishti glance", wide: true),
           CardInfo(id: "avasthas", title: "Avasthas", keywords: "states baladi jagradadi deeptadi mood", wide: true),
           CardInfo(id: "transits", title: "Transits", keywords: "gochara sky now table", wide: true),
           CardInfo(id: "kp-grahas", title: "KP grahas", keywords: "krishnamurti star sub lord", wide: true),
           CardInfo(id: "kp-cusps", title: "KP cusps (Placidus)", keywords: "krishnamurti houses bhava", wide: true),
           CardInfo(id: "kp-houses", title: "KP house significators", keywords: "krishnamurti occupants", wide: true),
           CardInfo(id: "kp-planets", title: "KP houses signified by grahas", keywords: "krishnamurti significators strong weak", wide: true)]

    static func info(_ id: String) -> CardInfo { all.first { $0.id == id } ?? CardInfo(id: id, title: id, keywords: "", wide: true) }
}

/// The workspace: wide cards one under another, runs of charts in a grid between them.
struct Workspace: View {
    @EnvironmentObject var store: Store

    private var runs: [[String]] {
        var result: [[String]] = []
        for id in store.cards {
            if !Catalog.info(id).wide, let last = result.last, let first = last.first, !Catalog.info(first).wide { result[result.count - 1].append(id) }
            else { result.append([id]) }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let problem = store.problem { Label(problem, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
                if store.showHelp {
                    Label(Help.workspace(store.workspace), systemImage: "lightbulb").font(.callout).foregroundStyle(.secondary)
                }
                if store.cards.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.dashed").font(.largeTitle).foregroundStyle(.secondary)
                        Text("This workspace is empty").font(.title3).fontWeight(.semibold)
                        Text("Press ⌘K and type what to add, such as “d9” or “transits”.").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(40)
                }
                ForEach(runs, id: \.self) { run in
                    if Catalog.info(run[0]).wide {
                        Card(id: run[0])
                    } else {
                        // up to three charts share one row whatever the width; a longer run flows into as many columns as fit
                        LazyVGrid(columns: run.count <= 3 ? Array(repeating: GridItem(.flexible(minimum: 150, maximum: 420), spacing: 14, alignment: .top), count: run.count)
                                                          : [GridItem(.adaptive(minimum: 240, maximum: 420), spacing: 14, alignment: .top)], alignment: .leading, spacing: 14) {
                            ForEach(run, id: \.self) { Card(id: $0) }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A card's frame: its title, its menu, and its content.
struct Card: View {
    @EnvironmentObject var store: Store
    let id: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Catalog.info(id).title).font(.headline).help(Help.card(id))
                Spacer()
                Menu {
                    Button("Move earlier") { store.moveCard(id, by: -1) }
                    Button("Move later") { store.moveCard(id, by: 1) }
                    Divider()
                    Button("Remove from this workspace") { store.removeCard(id) }
                } label: { Image(systemName: "ellipsis") }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                    .accessibilityLabel("Card options for \(Catalog.info(id).title)")
            }
            if store.showHelp, !Help.card(id).isEmpty {
                Text(Help.card(id)).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            content
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.08)))
    }

    @ViewBuilder private var content: some View {
        if id == "birth" {
            BirthForm()
        } else if id == "glossary" {
            GlossaryCard(chart: store.chart)
        } else if id == "sources" {
            SourcesCard()
        } else if let chart = store.chart {
            if id == "moon" {
                // the birth chart counted from the Moon's sign: the same signs, the Moon's as the first house
                ChartView(style: store.style, title: "Chandra", ascSign: chart.graha("Mo")?.sign ?? chart.asc.sign, marks: marks(chart, 0, lagnaLabel: true), aspected: aspected(chart))
            } else if id.hasPrefix("chart:"), let varga = Int(id.dropFirst(6)) {
                ChartView(style: store.style, title: Names.vargaCodes[varga], ascSign: chart.asc.vargas[varga], marks: marks(chart, varga), aspected: varga == 0 ? aspected(chart) : [])
            } else {
                switch id {
                case "karakas": KarakaCard(chart: chart)
                case "edges": EdgesCard(chart: chart)
                case "match": MatchCard(chart: chart)
                case "annual": AnnualCard(chart: chart)
                case "arudhas": ArudhaCard(chart: chart)
                case "chara-dasha": CharaDashaCard(chart: chart)
                case "guide": GuideCard(chart: chart)
                case "reading": ReadingCard(chart: chart)
                case "houses": HousesCard(chart: chart)
                case "grahas": GrahaTable(chart: chart)
                case "timeline": DashaTimeline(chart: chart)
                case "dasha-context": DashaContext(chart: chart)
                case "other-dashas": OtherDashas(chart: chart)
                case "dashas": DashaList(chart: chart)
                case "shadbala": ShadbalaTable(chart: chart)
                case "ashtakavarga": AshtakavargaTable(chart: chart)
                case "yogas": YogaList(chart: chart)
                case "aspects": AspectTable(chart: chart)
                case "avasthas": AvasthaTable(chart: chart)
                case "transits": TransitTable(natal: chart)
                case "transit-dates": TransitDates(natal: chart)
                case "kp-grahas": KPGrahas(kp: chart.kp)
                case "kp-cusps": KPCusps(kp: chart.kp)
                case "kp-houses": KPHouses(kp: chart.kp)
                case "kp-planets": KPPlanets(kp: chart.kp)
                default: Text("Unknown card").foregroundStyle(.secondary)
                }
            }
        } else {
            Text("No chart yet").foregroundStyle(.secondary)
        }
    }

    /// the signs the picked graha aspects, tinted in the birth chart
    private func aspected(_ chart: Chart) -> [Int] { store.pick?.graha.map { chart.aspectedSigns(by: $0) } ?? [] }

    /// Birth positions in a varga, with the sky's positions beside them while the desk stands away from the birth.
    private func marks(_ chart: Chart, _ varga: Int, lagnaLabel: Bool = false) -> [Int: [ChartMark]] {
        var bySign: [Int: [ChartMark]] = [chart.asc.vargas[varga]: [ChartMark(code: "As", label: "As", sign: lagnaLabel ? chart.asc.vargas[varga] : nil)]]
        for g in chart.grahas {
            let back = g.retro && g.id != "Ra" && g.id != "Ke", retro = back ? "℞" : ""
            bySign[g.vargas[varga], default: []].append(ChartMark(code: g.id, label: varga == 0 ? "\(g.id)\(retro) \(Int(g.deg))°" : g.id + retro, retro: back))
        }
        if let sky = store.sky {
            for g in sky.grahas { bySign[g.vargas[varga], default: []].append(ChartMark(code: g.id, label: varga == 0 ? "\(g.id) \(Int(g.deg))°" : g.id, transit: true, retro: g.retro && g.id != "Ra" && g.id != "Ke")) }
        }
        return bySign
    }
}

struct BirthForm: View {
    @EnvironmentObject var store: Store

    var body: some View {
        if let index = store.index {
            let birth = $store.births[index]
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                GridRow {
                    Text("Name"); TextField("Name", text: birth.name).frame(minWidth: 150)
                    Text("Date"); TextField("YYYY-MM-DD", text: birth.date).frame(width: 110)
                    Text("Time"); TextField("HH:MM:SS", text: birth.time).frame(width: 90)
                }
                GridRow {
                    Text("Place")
                    TextField("City, country", text: birth.place).onSubmit { store.lookUpPlace() }
                    Text("Latitude"); TextField("north +", value: birth.latitude, format: .number.precision(.fractionLength(0...4))).frame(width: 110)
                    Text("Longitude"); TextField("east +", value: birth.longitude, format: .number.precision(.fractionLength(0...4))).frame(width: 90)
                }
                GridRow {
                    Text("Time zone")
                    TextField("Area/City", text: birth.zone).foregroundStyle(birth.wrappedValue.timeZone == nil ? .red : .primary)
                    Button("Look up place") { store.lookUpPlace() }.disabled(birth.wrappedValue.place.isEmpty).gridCellColumns(4)
                        .help("Sends the place name to Apple's geocoder and fills latitude, longitude and time zone.")
                }
            }
            .textFieldStyle(.roundedBorder)
            .foregroundStyle(.secondary)
        }
    }
}

/// A table row that can be pointed at: it highlights with whatever else shows the same pick.
struct PickRow: View {
    @EnvironmentObject var store: Store
    var pick: Pick?
    var cells: [(text: String, width: CGFloat)]
    var tint: Color = .primary
    var header = false
    /// underline the first cell: a retrograde graha
    var retro = false

    var body: some View {
        let chosen = pick != nil && (store.pick == pick || (pick?.graha != nil && store.pick?.graha == pick?.graha))
        let near = pick != nil && (store.hover == pick || (pick?.graha != nil && store.hover?.graha == pick?.graha))
        HStack(spacing: 0) {
            ForEach(cells.indices, id: \.self) { index in
                Text(cells[index].text)
                    .font(header ? .caption : .body)
                    .fontWeight(index == 0 && !header ? .medium : .regular)
                    .underline(index == 0 && retro)
                    .foregroundStyle(header ? AnyShapeStyle(.secondary) : index == 0 ? AnyShapeStyle(tint) : AnyShapeStyle(.primary))
                    .lineLimit(1)
                    .frame(width: cells[index].width, alignment: .leading)
                    .help(header ? (Help.term(cells[index].text) ?? "") : "")
            }
        }
        .padding(.vertical, 2).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 5).fill(Color.accentColor.opacity(chosen ? 0.25 : near ? 0.1 : 0)))
        .contentShape(Rectangle())
        .onTapGesture { if let pick { store.pick = pick } }
        .onHover { inside in if let pick { store.hover = inside ? pick : (store.hover == pick ? nil : store.hover) } }
        .monospacedDigit()
    }
}

struct GrahaTable: View {
    let chart: Chart
    private let widths: [CGFloat] = [112, 86, 84, 150, 44, 96, 70, 96]

    private func row(_ texts: [String]) -> [(text: String, width: CGFloat)] { texts.indices.map { (texts[$0], widths[$0]) } }

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                PickRow(pick: nil, cells: row(["Graha", "Rasi", "Longitude", "Nakshatra", "Pada", "Rasi · star · sub", "Dignity", "Motion °/day"]), header: true)
                PickRow(pick: .sign(chart.asc.sign), cells: row(["Lagna", Names.signs[chart.asc.sign], Names.dms(chart.asc.deg), chart.asc.nak_name, "\(chart.asc.pada)",
                                                                  "\(chart.asc.rasi_lord) · \(chart.asc.nak_lord) · \(chart.asc.sub_lord)", "", ""]), tint: .accentColor)
                ForEach(chart.grahas) { g in
                    PickRow(pick: .graha(g.id), cells: row(["\(g.name) (\(g.id))", Names.signs[g.sign], Names.dms(g.deg), g.nak_name, "\(g.pada)",
                                                             "\(g.rasi_lord) · \(g.nak_lord) · \(g.sub_lord)", (g.status ?? "") + (g.combust == true ? " C" : ""),
                                                             String(format: "%+.4f", g.speed) + (g.retro && g.id != "Ra" && g.id != "Ke" ? " ℞" : "")]), tint: Tint.graha(g.id), retro: g.retro && g.id != "Ra" && g.id != "Ke")
                }
            }
        }
    }
}

struct TransitTable: View {
    @EnvironmentObject var store: Store
    let natal: Chart
    private let widths: [CGFloat] = [112, 86, 84, 150, 44, 96, 84, 84]

    var body: some View {
        if let sky = store.sky {
            let moon = natal.graha("Mo")?.sign ?? 0
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 1) {
                    PickRow(pick: nil, cells: zip(["Graha", "Rasi", "Longitude", "Nakshatra", "Pada", "Motion °/day", "From lagna", "From Moon"], widths).map { ($0, $1) }, header: true)
                    ForEach(sky.grahas + sky.outer) { g in
                        PickRow(pick: .graha(g.id), cells: zip([g.name, Names.signs[g.sign], Names.dms(g.deg), g.nak_name, "\(g.pada)",
                                                                 String(format: "%+.4f", g.speed) + (g.retro && g.id != "Ra" && g.id != "Ke" ? " ℞" : ""),
                                                                 "house \((g.sign - natal.asc.sign + 12) % 12 + 1)", "house \((g.sign - moon + 12) % 12 + 1)"], widths).map { ($0, $1) },
                                tint: Tint.graha(g.id), retro: g.retro && g.id != "Ra" && g.id != "Ke")
                    }
                }
            }
        } else {
            HStack {
                Text("The desk stands at the birth. Move the time bar to see the sky of another moment over this chart.").foregroundStyle(.secondary)
                Button("Go to now") { store.goNow() }
            }
        }
    }
}

// MARK: Krishnamurti Paddhati

struct KPGrahas: View {
    let kp: KP
    private let widths: [CGFloat] = [112, 86, 84, 150, 70, 70, 70, 70]
    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                PickRow(pick: nil, cells: zip(["Graha", "Rasi", "Longitude", "Nakshatra", "Rasi lord", "Star lord", "Sub lord", "Sub-sub"], widths).map { ($0, $1) }, header: true)
                ForEach(kp.grahas + kp.outer) { g in
                    PickRow(pick: .graha(g.id), cells: zip([g.name, Names.signs[g.sign], Names.dms(g.deg), g.nak_name, g.rasi_lord, g.nak_lord, g.sub_lord, g.sub_sub], widths).map { ($0, $1) }, tint: Tint.graha(g.id), retro: g.retro && g.id != "Ra" && g.id != "Ke")
                }
                Text("KP ayanamsa \(Names.dms(kp.ayanamsa)) · Fortuna \(Names.signs[kp.fortuna.sign]) \(Names.dms(kp.fortuna.deg))").font(.footnote).foregroundStyle(.secondary).padding(.top, 4)
            }
        }
    }
}

struct KPCusps: View {
    let kp: KP
    private let widths: [CGFloat] = [60, 86, 84, 150, 70, 70, 70, 70]
    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                PickRow(pick: nil, cells: zip(["Cusp", "Rasi", "Longitude", "Nakshatra", "Rasi lord", "Star lord", "Sub lord", "Sub-sub"], widths).map { ($0, $1) }, header: true)
                ForEach(kp.cusps.indices, id: \.self) { index in
                    let c = kp.cusps[index]
                    PickRow(pick: .sign(c.sign), cells: zip(["\(index + 1)", Names.signs[c.sign], Names.dms(c.deg), c.nak_name, c.rasi_lord, c.nak_lord, c.sub_lord, c.sub_sub], widths).map { ($0, $1) })
                }
            }
        }
    }
}

struct KPHouses: View {
    let kp: KP
    private let widths: [CGFloat] = [60, 170, 130, 170, 90]
    var body: some View {
        let reading = KPReading(kp: kp)
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                PickRow(pick: nil, cells: zip(["House", "In stars of occupants", "Occupants", "In stars of cusp lord", "Cusp lord"], widths).map { ($0, $1) }, header: true)
                ForEach(0..<12, id: \.self) { house in
                    let row = reading.houseRow(house)
                    PickRow(pick: .sign(kp.cusps[house].sign), cells: zip(["\(house + 1)", row.starsOfOccupants.joined(separator: ", "), row.occupants.joined(separator: ", "),
                                                                           row.starsOfLord.joined(separator: ", "), row.lord], widths).map { ($0, $1) })
                }
            }
        }
    }
}

struct KPPlanets: View {
    let kp: KP
    private let widths: [CGFloat] = [112, 100, 100, 100, 120]
    var body: some View {
        let reading = KPReading(kp: kp), list = { (h: [Int]) in h.map(String.init).joined(separator: " ") }
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                PickRow(pick: nil, cells: zip(["Graha", "Very strong", "Strong", "Normal", "Weak"], widths).map { ($0, $1) }, header: true)
                ForEach(kp.grahas) { g in
                    let s = reading.signified(by: g)
                    PickRow(pick: .graha(g.id), cells: zip([g.name, list(s.veryStrong), list(s.strong), list(s.normal), list(s.weak)], widths).map { ($0, $1) }, tint: Tint.graha(g.id))
                }
            }
        }
    }
}
