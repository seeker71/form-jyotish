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
        + [CardInfo(id: "events", title: "Life events against the dashas", keywords: "events dates happened marriage career test verify rectify bhukti timeline biography", wide: true),
           CardInfo(id: "match", title: "Match: two charts by the eight kootas", keywords: "relationship compatibility marriage guna milan ashtakoota kundli matching partner synastry koota", wide: true),
           CardInfo(id: "edges", title: "Near an edge", keywords: "boundary cusp sandhi gandanta sensitive birth time ayanamsa sign change junction", wide: true),
           CardInfo(id: "annual", title: "Annual chart (Varshaphal)", keywords: "varshaphal tajika solar return year muntha varsha birthday", wide: true),
           CardInfo(id: "sources", title: "Sources and voice", keywords: "references texts parashara raman rao method trust how", wide: true),
           CardInfo(id: "karakas", title: "Chara karakas", keywords: "jaimini atmakaraka amatyakaraka darakaraka karakamsa significators", wide: true),
           CardInfo(id: "arudhas", title: "Arudha padas", keywords: "jaimini pada arudha lagna upapada image", wide: true),
           CardInfo(id: "chara-dasha", title: "Chara dasha", keywords: "jaimini rasi sign dasha rao", wide: true),
           CardInfo(id: "glossary", title: "Glossary", keywords: "dictionary terms words meaning search look up what is", wide: true),
           CardInfo(id: "guide", title: "First steps: how a chart is read", keywords: "learn tutorial lesson teach help", wide: true),
           CardInfo(id: "reading", title: "This chart at a glance", keywords: "summary overview plain words", wide: true),
           CardInfo(id: "zodiac", title: "The zodiac: sidereal and tropical", keywords: "ayanamsa precession equinox solstice seasons lahiri chitra spica tropical sidereal moving portion", wide: true),
           CardInfo(id: "rashi-meanings", title: "Rashi characteristics", keywords: "signs constellations element dosha direction head rising back rising shirshodaya body parts fruitful barren odd even movable fixed dual", wide: true),
           CardInfo(id: "bhava-classes", title: "Bhava classifications and the four aims", keywords: "kendra trikona trik dusthana maraka upachaya panaphara apoklima dharma artha kama moksha purushartha trines houses classes", wide: true),
           CardInfo(id: "bhava-karakas", title: "Bhava karakas: the house significators", keywords: "karaka significator house bhava sun jupiter mars moon venus saturn mercury", wide: true),
           CardInfo(id: "bhava-meanings", title: "Bhava significations", keywords: "house meanings significations tanu dhana bhratri sukha putra shatru kalatra mrityu bhagya karma labha vyaya", wide: true),
           CardInfo(id: "graha-meanings", title: "Graha significations", keywords: "planet meanings significations rulerships soul mind father mother essence people nature", wide: true),
           CardInfo(id: "houses", title: "The twelve houses", keywords: "bhava lords areas of life", wide: true),
           CardInfo(id: "moon", title: "Chandra chart", keywords: "moon chandra lagna", wide: false),
           CardInfo(id: "grahas", title: "Grahas", keywords: "planets table positions nakshatra lords dignity", wide: true),
           CardInfo(id: "timeline", title: "Vimshottari timeline", keywords: "dasha graph periods zoom", wide: true),
           CardInfo(id: "dasha-context", title: "The running period in context", keywords: "dasha now current mahadasha antardasha lords meaning transit sade sati", wide: true),
           CardInfo(id: "other-dashas", title: "Other dasha systems", keywords: "ashtottari yogini shodashottari dwadashottari panchottari shatabdika chaturashiti dwisaptati shat-trimsha conditional", wide: true),
           CardInfo(id: "dashas", title: "Vimshottari periods", keywords: "dasha list mahadasha antardasha pratyantardasha sookshma", wide: true),
           CardInfo(id: "panchanga", title: "Panchanga: the five limbs of the day", keywords: "panchanga vara weekday hora tithi karana yoga nakshatra gandanta day", wide: true),
           CardInfo(id: "gochara", title: "Transits from the Moon (gochara)", keywords: "gochara vedha moon chandra lagna transit favourable", wide: true),
           CardInfo(id: "dina", title: "The day now: five limbs", keywords: "panchanga today muhurta tithi vara hora nakshatra karana yoga now choose time", wide: true),
           CardInfo(id: "transit-dates", title: "Transit dates", keywords: "gochara ingress station retrograde sade sati exact dates events", wide: true),
           CardInfo(id: "bala-sky", title: "The sky at birth: Moon, eclipse, retrogression, combustion, war", keywords: "moon full new waxing waning dark bright eclipse lunar solar retrograde combust planetary war graha yuddha", wide: true),
           CardInfo(id: "bala-table", title: "Graha strength and weakness", keywords: "strength weakness own sign exaltation debilitation dig bala retrograde combust planetary war table light on life", wide: true),
           CardInfo(id: "bala-keys", title: "Primary and secondary strength", keywords: "strength weakness primary secondary benefic malefic flanked friend enemy full new moon eclipse", wide: true),
           CardInfo(id: "bala-relations", title: "Graha relations", keywords: "friends neutrals enemies mitra sama shatru natural friendship camps", wide: true),
           CardInfo(id: "bala-charts", title: "Visualizing strength", keywords: "rulership own sign exaltation dig bala directional charts", wide: true),
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

    /// The least width at which a card still reads well beside others. A card not named here takes a row to itself.
    static let shared: [String: CGFloat] = [
        "grahas": 560, "birth": 440, "edges": 420, "reading": 420, "dasha-context": 440, "yogas": 440, "dashas": 420, "other-dashas": 440,
        "karakas": 440, "arudhas": 600, "chara-dasha": 440, "kp-grahas": 540, "kp-cusps": 540, "kp-houses": 540, "kp-planets": 540,
        "transit-dates": 440, "gochara": 560, "dina": 520, "panchanga": 520, "ashtakavarga": 520, "avasthas": 620, "aspects": 600, "events": 460]
    /// long cards: beside another card they scroll within the height on screen, so their neighbour stays in view
    /// cards whose method Light on Life does not teach: each is marked, and stands after the book's cards
    static let additions: Set<String> = ["shadbala", "ashtakavarga", "other-dashas", "karakas", "arudhas", "chara-dasha", "kp-grahas", "kp-cusps", "kp-houses", "kp-planets", "annual", "match"]
    /// the colour that marks whatever stands outside the textbook
    static let additionTint = Color.purple
    static let long: Set<String> = ["yogas", "dashas", "other-dashas", "events", "transit-dates"]

    static func info(_ id: String) -> CardInfo { all.first { $0.id == id } ?? CardInfo(id: id, title: id, keywords: "", wide: true) }
}

/// The workspace: neighbouring cards share a row where the window has room for each to read well; a card
/// that needs the full width takes a row to itself.
struct Workspace: View {
    @EnvironmentObject var store: Store

    private func isChart(_ id: String) -> Bool { !Catalog.info(id).wide }
    /// the least width a card needs to share a row; nil for a card that takes the full width
    private func least(_ id: String) -> CGFloat? { isChart(id) ? (store.enlarged.contains(id) ? 360 : 230) : Catalog.shared[id] }

    /// The cards in rows, in their order: each row takes the next card while its least width still fits.
    private func rows(width: CGFloat) -> [[String]] {
        let room = width - 32
        var result: [[String]] = [], used = CGFloat.infinity
        for id in store.cards where store.showAdditions || !Catalog.additions.contains(id) {
            guard let need = least(id) else { result.append([id]); used = .infinity; continue }
            if used + 14 + need <= room { result[result.count - 1].append(id); used += 14 + need } else { result.append([id]); used = need }
        }
        return result
    }

    /// The width each card of a row takes. Charts alone share the row evenly; beside tables a chart takes the
    /// size that shows whole in the window (its largest when enlarged), as far as the tables can spare it.
    private func widths(_ row: [String], width: CGFloat, height: CGFloat) -> [CGFloat] {
        let room = width - 32 - CGFloat(row.count - 1) * 14
        let tallest = max(150, height - (store.showHelp ? 150 : 80))
        let charts = row.filter(isChart), others = row.count - charts.count
        let anyLarge = charts.contains { store.enlarged.contains($0) }
        if others == 0 && !anyLarge { return row.map { _ in max(150, min(room / CGFloat(row.count), tallest)) } }
        if charts.isEmpty { return row.map { _ in room / CGFloat(others) } }
        let spare = room - row.filter { !isChart($0) }.reduce(0) { $0 + (least($1) ?? 0) }
        let want = charts.map { store.enlarged.contains($0) ? tallest : min(tallest, 300) }
        let scale = min(1, spare / want.reduce(0, +))
        let chartWidth = Dictionary(uniqueKeysWithValues: zip(charts, want.map { $0 * scale }))
        let rest = others == 0 ? 0 : (room - chartWidth.values.reduce(0, +)) / CGFloat(others)
        return row.map { chartWidth[$0] ?? rest }
    }

    var body: some View {
        // below this width the cards keep their shape and the workspace scrolls sideways
        GeometryReader { geo in content(width: max(geo.size.width, Workspace.narrowest), height: geo.size.height, sideways: geo.size.width < Workspace.narrowest) }
    }

    static let narrowest: CGFloat = 560

    private func content(width: CGFloat, height: CGFloat, sideways: Bool) -> some View {
        ScrollViewReader { reader in
        ScrollView(sideways ? [.vertical, .horizontal] : .vertical) {
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
                ForEach(rows(width: width), id: \.self) { row in
                    let each = widths(row, width: width, height: height)
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(Array(row.enumerated()), id: \.element) { index, id in
                            Card(id: id, limit: row.count > 1 && Catalog.long.contains(id) ? max(300, height - 40) : nil)
                                .id(id).frame(width: each[index])
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.22), value: store.cards)
            .animation(.easeInOut(duration: 0.22), value: store.enlarged)
            .padding(16)
            .frame(width: width, alignment: .leading)
        }
        .onChanged(of: store.showCard) { if let card = store.showCard { withAnimation { reader.scrollTo(card, anchor: .top) }; store.showCard = nil } }
        }
    }
}

/// A card's frame: its title, its menu, and its content.
struct Card: View {
    @EnvironmentObject var store: Store
    let id: String
    /// the height the card may take before its content scrolls within it; nil lets it grow
    var limit: CGFloat? = nil
    @State private var hovering = false
    @State private var targeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Catalog.info(id).title).font(.headline).help(Help.card(id) + " Drag this title onto another card to move the card there.")
                    .draggable(id)
                if Catalog.additions.contains(id) {
                    Text("ADDITION · not in Light on Life").font(.caption2).fontWeight(.bold).foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 2).background(Capsule().fill(Catalog.additionTint))
                        .help("A method that Light on Life does not teach. It is kept as an optional addition; the Additions switch in the tab bar hides every such card.")
                }
                Spacer()
                Button { store.explanation = Help.about(card: id) } label: { Image(systemName: "questionmark.circle") }
                    .buttonStyle(.plain).foregroundStyle(.secondary).accessibilityLabel("About \(Catalog.info(id).title)")
                    .help("What this card shows, how it is reached, and what to try")
                if !Catalog.info(id).wide {
                    Button { store.toggleEnlarged(id) } label: { Image(systemName: store.enlarged.contains(id) ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") }
                        .buttonStyle(.plain).foregroundStyle(.secondary)
                        .accessibilityLabel(store.enlarged.contains(id) ? "Make this chart smaller" : "Make this chart larger")
                        .help(store.enlarged.contains(id) ? "Draw this chart at its usual size, beside the others" : "Draw this chart large, with larger letters, on a row of its own")
                }
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
                Text(store.familiar ? (Help.method(id) ?? Help.card(id)) : Help.card(id)).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            if let limit { ScrollView { content.frame(maxWidth: .infinity, alignment: .leading) }.frame(maxHeight: limit - 70) } else { content }
            if let words = legend { Text(words).font(.caption).foregroundStyle(.secondary).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading) }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(targeted ? Color.accentColor : Color.primary.opacity(hovering ? 0.25 : 0.08), lineWidth: targeted ? 2 : 1))
        .background(RoundedRectangle(cornerRadius: 10).fill(Catalog.additionTint.opacity(Catalog.additions.contains(id) ? 0.07 : 0)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Catalog.additionTint.opacity(Catalog.additions.contains(id) ? 0.85 : 0), style: StrokeStyle(lineWidth: 1.5, dash: [7, 4])))
        .onHover { hovering = $0 }
        .dropDestination(for: String.self) { items, _ in
            guard let moved = items.first, moved != id, store.cards.contains(moved) else { return false }
            store.moveCard(moved, onto: id)
            return true
        } isTargeted: { targeted = $0 }
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
                ChartView(style: store.style, title: "Chandra", ascSign: chart.graha("Mo")?.sign ?? chart.asc.sign, marks: marks(chart, 0, lagnaLabel: true), aspected: aspected(chart), owned: owned(chart))
            } else if id.hasPrefix("chart:"), let varga = Int(id.dropFirst(6)) {
                ChartView(style: store.style, title: Names.vargaCodes[varga], ascSign: chart.asc.vargas[varga], marks: marks(chart, varga), aspected: varga == 0 ? aspected(chart) : [], owned: varga == 0 ? owned(chart) : [])
            } else {
                switch id {
                case "karakas": KarakaCard(chart: chart)
                case "edges": EdgesCard(chart: chart)
                case "events": EventsCard(chart: chart)
                case "match": MatchCard(chart: chart)
                case "annual": AnnualCard(chart: chart)
                case "arudhas": ArudhaCard(chart: chart)
                case "chara-dasha": CharaDashaCard(chart: chart)
                case "guide": GuideCard(chart: chart)
                case "reading": ReadingCard(chart: chart)
                case "zodiac": ZodiacCard(chart: chart)
                case "rashi-meanings": RashiMeaningsCard(chart: chart)
                case "bhava-classes": BhavaClassCard(chart: chart)
                case "bhava-karakas": BhavaKarakaCard(chart: chart)
                case "bhava-meanings": BhavaMeaningsCard(chart: chart)
                case "graha-meanings": GrahaMeaningsCard(chart: chart)
                case "houses": HousesCard(chart: chart)
                case "grahas": GrahaTable(chart: chart)
                case "timeline": DashaTimeline(chart: chart)
                case "dasha-context": DashaContext(chart: chart)
                case "other-dashas": OtherDashas(chart: chart)
                case "dashas": DashaList(chart: chart)
                case "bala-sky": StrengthSky(chart: chart)
                case "bala-table": StrengthSheet(chart: chart)
                case "bala-keys": KeyFactorsCard(chart: chart)
                case "bala-relations": RelationsCard(chart: chart)
                case "bala-charts": StrengthCharts(chart: chart)
                case "shadbala": ShadbalaTable(chart: chart)
                case "ashtakavarga": AshtakavargaTable(chart: chart)
                case "yogas": YogaList(chart: chart)
                case "aspects": AspectTable(chart: chart)
                case "avasthas": AvasthaTable(chart: chart)
                case "transits": TransitTable(natal: chart)
                case "gochara": GocharaCard(natal: chart)
                case "dina": DayNowCard(natal: chart)
                case "panchanga": PanchangaCard(chart: chart)
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

    /// the signs the graha in focus (under the pointer, else clicked) aspects, and the signs it rules: tinted in the birth chart
    private func aspected(_ chart: Chart) -> [Int] { store.focus?.graha.map { chart.aspectedSigns(by: $0) } ?? [] }
    private func owned(_ chart: Chart) -> [Int] { store.focus?.graha.map { code in chart.housesRuled(by: code).map { (chart.asc.sign + $0 - 1) % 12 } } ?? [] }
    /// Under a birth chart, what the tints mean. The line always stands there, one line high, so the cards
    /// below keep their place while the pointer moves over the chart.
    private var legend: String? {
        guard id == "chart:0" || id == "moon" else { return nil }
        let rest = "Point at a graha to tint the signs it aspects and rules."
        guard let chart = store.chart, let code = store.focus?.graha, chart.graha(code) != nil else { return rest }
        let name = Names.lords[code] ?? code, seen = aspected(chart), ruled = owned(chart)
        let parts = [seen.isEmpty ? nil : "orange: the signs \(name) aspects", ruled.isEmpty ? nil : "green: the signs \(name) rules"].compactMap { $0 }
        return parts.isEmpty ? rest : parts.joined(separator: " · ")
    }

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
    private enum Field { case place, date, time }
    @FocusState private var focus: Field?
    @State private var left: Field?
    @State private var placeBefore = ""
    /// the chart whose place the cursor entered: a place is looked up only for the chart it was typed into
    @State private var placeOf: Birth.ID?

    /// A field resolves when the cursor leaves it: the date and time are written out in full, and a changed
    /// place is looked up and written as matched, with its latitude, longitude and time zone.
    private func resolve(_ field: Field?) {
        guard let field, let index = store.index else { return }
        switch field {
        case .date: if let written = store.births[index].writtenDate { store.births[index].date = written }
        case .time: if let written = store.births[index].writtenTime { store.births[index].time = written }
        case .place: if store.births[index].id == placeOf, store.births[index].place != placeBefore, !store.births[index].place.isEmpty { store.lookUpPlace() }
        }
    }
    var body: some View {
        if let index = store.index {
            let birth = $store.births[index]
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                // two pairs to a row: the form keeps its shape at any text size
                GridRow {
                    Text("Name"); TextField("Name", text: birth.name).frame(minWidth: 150)
                    Text("Place"); TextField("City, country", text: birth.place).focused($focus, equals: .place).onSubmit { store.lookUpPlace(); placeBefore = birth.wrappedValue.place }.frame(minWidth: 150)
                }
                GridRow {
                    Text("Date"); TextField("1971-Mar-11", text: birth.date).focused($focus, equals: .date).onSubmit { resolve(.date) }.frame(minWidth: 130)
                        .foregroundStyle(birth.wrappedValue.writtenDate == nil ? .red : .primary).help("Any common form: 1971-03-11, 11 Mar 1971, 11.3.1971. It is written as 1971-Mar-11 when you leave the field, so month and day cannot be taken for each other; red means it cannot be read yet.")
                    Text("Time"); TextField("02:50 or 2:50 am", text: birth.time).focused($focus, equals: .time).onSubmit { resolve(.time) }.frame(minWidth: 110)
                        .foregroundStyle(birth.wrappedValue.writtenTime == nil ? .red : .primary).help("The clock time at the birthplace: 02:50, 2:50 am, 0250. It is written out as 02:50:00 when you leave the field; red means it cannot be read yet.")
                }
                GridRow {
                    Text("Latitude"); TextField("north +", value: birth.latitude, format: .number.precision(.fractionLength(0...4))).frame(width: 110)
                    Text("Longitude"); TextField("east +", value: birth.longitude, format: .number.precision(.fractionLength(0...4))).frame(width: 110)
                }
                GridRow {
                    Text("Time zone")
                    TextField("Area/City", text: birth.zone).foregroundStyle(birth.wrappedValue.timeZone == nil ? .red : .primary)
                    Button("Look up place") { store.lookUpPlace() }.disabled(birth.wrappedValue.place.isEmpty).gridCellColumns(2)
                        .help("Sends the place name to Apple's geocoder and fills latitude, longitude and time zone.")
                }
            }
            .textFieldStyle(.roundedBorder)
            .foregroundStyle(.secondary)
            .onChange(of: focus) { now in
                resolve(left)
                left = now
                if now == .place { placeBefore = birth.wrappedValue.place; placeOf = birth.wrappedValue.id }
            }
            .onChange(of: store.current) { _ in placeOf = nil; left = nil; focus = nil }
            if let source = birth.wrappedValue.source, !source.isEmpty {
                Text("Source. " + source).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).padding(.top, 4)
            }
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
    /// where the first heading with an explanation and the first row of each graha stand: read by the click witness (`--probe-table`)
    static var spots: [String: CGRect] = [:]
    private func mark(_ key: String) -> some View {
        GeometryReader { geo in let place = geo.frame(in: .global); Color.clear.onAppear { if PickRow.spots[key] == nil { PickRow.spots[key] = place } }.onChanged(of: place) { PickRow.spots[key] = geo.frame(in: .global) } }
    }

    var body: some View {
        let chosen = pick != nil && (store.pick == pick || (pick?.graha != nil && store.pick?.graha == pick?.graha))
        let near = pick != nil && (store.hover == pick || (pick?.graha != nil && (store.hover?.graha == pick?.graha || store.glow.contains(pick?.graha ?? ""))))
        HStack(spacing: 0) {
            ForEach(cells.indices, id: \.self) { index in
                Text(cells[index].text)
                    .font(header ? .caption : .body)
                    .fontWeight(index == 0 && !header ? .medium : .regular)
                    .underline(index == 0 && retro)
                    .foregroundStyle(header ? AnyShapeStyle(.secondary) : index == 0 ? AnyShapeStyle(tint) : AnyShapeStyle(.primary))
                    .lineLimit(1)
                    .frame(width: cells[index].width, alignment: .leading)
                    .underline(header && Help.term(cells[index].text) != nil, pattern: .dot, color: Color.secondary.opacity(0.6))
                    .help(header ? (Help.term(cells[index].text).map { $0 + " Click for more." } ?? "") : "")
                    .onTapGesture { if header, Help.term(cells[index].text) != nil { store.explanation = Lore.explain(term: cells[index].text, chart: store.chart) } else if let pick { store.pick = pick } }
                    .background { if header, Help.term(cells[index].text) != nil { mark("heading:" + cells[index].text) } else if index == 0, let code = pick?.graha { mark("row:" + code) } }
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
    /// narrow enough to stand whole in the workspace at the larger text sizes: the seconds of arc and the
    /// finer digits of motion are a click away in the inspector
    private let widths: [CGFloat] = [92, 70, 54, 134, 68, 60, 46]

    private func row(_ texts: [String]) -> [(text: String, width: CGFloat)] { texts.indices.map { (texts[$0], widths[$0]) } }
    /// degrees and minutes within the sign
    private func place(_ deg: Double) -> String { let m = Int(deg * 60); return "\(m / 60)°\(String(format: "%02d", m % 60))′" }

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 0) {
                PickRow(pick: nil, cells: row(["Graha", "Rasi", "Long.", "Nakshatra · pada", "Lords", "Dignity", "°/day"]), header: true)
                PickRow(pick: .sign(chart.asc.sign), cells: row(["Lagna", Names.signs[chart.asc.sign], place(chart.asc.deg), "\(chart.asc.nak_name) \(chart.asc.pada)",
                                                                  "\(chart.asc.rasi_lord)·\(chart.asc.nak_lord)·\(chart.asc.sub_lord)", "", ""]), tint: .accentColor)
                ForEach(chart.grahas) { g in
                    PickRow(pick: .graha(g.id), cells: row(["\(g.name) (\(g.id))", Names.signs[g.sign], place(g.deg), "\(g.nak_name) \(g.pada)",
                                                             "\(g.rasi_lord)·\(g.nak_lord)·\(g.sub_lord)", (g.status ?? "") + (g.combust == true ? " C" : ""),
                                                             String(format: "%+.2f", g.speed)]), tint: Tint.graha(g.id), retro: g.retro && g.id != "Ra" && g.id != "Ke")
                }
            }
        }
    }
}

struct TransitTable: View {
    @EnvironmentObject var store: Store
    let natal: Chart
    private let widths: [CGFloat] = [104, 84, 84, 84, 84, 150, 44, 96]

    var body: some View {
        if let sky = store.sky {
            let moon = natal.graha("Mo")?.sign ?? 0
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 1) {
                    PickRow(pick: nil, cells: zip(["Graha", "Rasi", "From lagna", "From Moon", "Longitude", "Nakshatra", "Pada", "Motion °/day"], widths).map { ($0, $1) }, header: true)
                    ForEach(sky.grahas + sky.outer) { g in
                        PickRow(pick: .graha(g.id), cells: zip([g.name, Names.signs[g.sign], "house \((g.sign - natal.asc.sign + 12) % 12 + 1)", "house \((g.sign - moon + 12) % 12 + 1)", Names.dms(g.deg), g.nak_name, "\(g.pada)",
                                                                 String(format: "%+.4f", g.speed) + (g.retro && g.id != "Ra" && g.id != "Ke" ? " ℞" : "")], widths).map { ($0, $1) },
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
