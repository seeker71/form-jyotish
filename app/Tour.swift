import SwiftUI

/// One step of the walk-through: what to look at in this chart, said in plain words, with the desk set to show it.
struct TourStep {
    var title: String
    /// what this chart shows at this step
    var words: String
    /// the finer point, for a reader who knows the tradition
    var detail: String
    /// something to do with the pointer, so the step is tried and not only read
    var tryIt: String
    var workspace: String
    var pick: Pick? = nil
    var card: String? = nil
    var glow: [String] = []
    var now = false
}

extension Chart {
    /// The walk-through of this chart, in the order a chart is read.
    func tour(day: Double, atBirth: Bool) -> [TourStep] {
        let name = { (code: String) in Names.lords[code] ?? code }
        let lines = glance(day: day, atBirth: atBirth)
        let said = { (heading: String) in lines.first { $0.heading.hasPrefix(heading) }?.words ?? "" }
        let lagnaLord = lord(ofHouse: 1), lordGraha = graha(lagnaLord), moon = graha("Mo")
        let weighed = lordGraha.map { factors(for: $0) }
        let running = dasha.first { $0.holds(day) }
        let firstYoga = yogas.first { !$0.grahas.isEmpty }
        let list = { (items: [String]) in items.prefix(3).joined(separator: "; ") }
        return [
            TourStep(title: "The lagna", words: said("The lagna") + " Every house is counted from this sign.",
                     detail: "Houses are whole signs from \(Names.signs[asc.sign]). The lagna stands at \(Names.dms(asc.deg)) in \(asc.nak_name), pada \(asc.pada).",
                     tryIt: "Rest the pointer on any sign of the chart. The panel below says which house it is, who rules it and who looks at it.",
                     workspace: "Overview", pick: .sign(asc.sign), card: "chart:0"),
            TourStep(title: "The lord of the lagna", words: "\(name(lagnaLord)) rules the rising sign and so carries the whole chart."
                        + (weighed.map { w in (w.supports.isEmpty ? "" : " What supports it: \(list(w.supports)).") + (w.strains.isEmpty ? "" : " What asks more of it: \(list(w.strains)).") } ?? ""),
                     detail: lordGraha.map { "It stands at \(Names.dms($0.deg)) \(Names.signs[$0.sign]) in \($0.nak_name), pada \($0.pada); navamsa \(Names.signs[$0.vargas[5]])." } ?? "",
                     tryIt: "In the chart, orange marks the signs it aspects and green the signs it rules. Below, click a fact such as Dignity or Navamsa to read what it means.",
                     workspace: "Overview", pick: .graha(lagnaLord), card: "chart:0"),
            TourStep(title: "The Moon", words: said("The Moon") + " The Moon is the mind, and its sign is read as a second lagna.",
                     detail: moon.map { "Chandra lagna is \(Names.signs[$0.sign]). Vimshottari opens in the dasha of \(name($0.nak_lord)), lord of \($0.nak_name)." } ?? "",
                     tryIt: "Compare the Chandra chart with the Rasi chart beside it. What holds from both lagnas is firm.",
                     workspace: "Overview", pick: .graha("Mo"), card: "chart:0"),
            TourStep(title: "The Sun and the lunar day", words: said("The Sun") + " The Sun is the self and vitality; the Moon's distance from it gives the lunar day of birth.",
                     detail: "Day: \(Names.tithi(self.day.tithi)). The Sun's dignity and the Moon's phase both enter the strength count.",
                     tryIt: "Click the Sun in the Grahas table. Its row lights on every card.",
                     workspace: "Overview", pick: .graha("Su"), card: "grahas"),
            TourStep(title: "The twelve houses", words: "Each house is an area of life. For each one, four things are read: its sign, where its lord has gone, who stands in it, and who looks at it.",
                     detail: "Aspects are full graha drishti by sign. Bindus are the sign's total in the sarvashtakavarga: 30 or more is strong support, 24 or fewer little.",
                     tryIt: "Click a row of the table. That house is picked on every card, and its meaning opens under the row.",
                     workspace: "Guide", pick: .sign(sign(ofHouse: 10)), card: "houses"),
            TourStep(title: "Condition and strength", words: said("Condition of the grahas") + " " + said("Strength"),
                     detail: "Shadbala sums six strengths in virupas; the last row is the ratio to the minimum the tradition asks. Ashtakavarga gives each sign's support for each graha.",
                     tryIt: "Rest the pointer on a column of Shadbala or a sign of Ashtakavarga. The chart beside it shows where that graha or sign stands.",
                     workspace: "Strength", pick: .graha(lagnaLord), card: "chart:0"),
            TourStep(title: "The yogas", words: said("Yogas") + " A yoga colours the chart; it gives in the periods of its grahas and in the measure of their strength.",
                     detail: "Each row states the rule met, so the rule can be checked. Where schools differ, both forms are listed with the rule in the name.",
                     tryIt: "Rest the pointer on a yoga: its grahas light up in the chart. Click it for its rule, the tradition's reading and a reading to work with.",
                     workspace: "Yogas", card: "chart:0", glow: firstYoga?.grahas ?? []),
            TourStep(title: "The navamsa", words: "The navamsa divides each sign into nine. It is read beside the birth chart for a graha's inner strength: a graha strong in both holds its promise."
                        + (lordGraha.flatMap { g in navamsaStanding(g).map { " The lagna lord, \(name(lagnaLord)), is \($0.word) in the navamsa." } } ?? ""),
                     detail: "A graha in the same sign in Rasi and navamsa is vargottama. The sixteen vargas each examine one area in finer detail.",
                     tryIt: "Rest the pointer on a graha in one chart. It lights in all sixteen, so its path through the vargas can be followed.",
                     workspace: "Vargas", pick: .graha(lagnaLord), card: "chart:5"),
            TourStep(title: "Whose time it is", words: said("The time") + " A graha's promise comes forward in its own periods.",
                     detail: "Vimshottari is counted from the Moon's nakshatra, with a year of 365.25 days. The running lords are read by the houses they rule and occupy.",
                     tryIt: "Press the arrows in the time bar at the bottom. The running period, the timeline and the charts all follow the moment.",
                     workspace: "Dasha", pick: running.map { .period(lords: [$0.lord], start: $0.start, end: $0.end) }, card: "chart:0"),
            TourStep(title: "What is passing", words: "The present sky is now laid over the birth chart: the italic marks are today's positions. Saturn and Jupiter set the season; they act within what the dasha allows.",
                     detail: "Transit houses are counted from the lagna and from the Moon. Saturn in the 12th, 1st and 2nd from the Moon is Sade Sati.",
                     tryIt: "Press Play in the time bar and watch the sky move over the chart. Press Birth to return to the birth chart alone.",
                     workspace: "Transits", card: "chart:0", now: true),
            TourStep(title: "From here", words: "Everything on the desk answers the pointer and a click. Press ⌘K and type any word, such as “What is Shadbala?” or a yoga's name, for its meaning. The ? on each card says what the card shows, how it is calculated and what to try.",
                     detail: "Guidance in the sidebar chooses between Learning (plain words on each card), Familiar (the method and conventions) and Off. Ayanamsa and node are kept with each chart.",
                     tryIt: "Open the glossary below and type a word you met on the way.",
                     workspace: "Guide", card: "glossary"),
        ]
    }
}

extension Store {
    var tourSteps: [TourStep] { chart?.tour(day: viewDay ?? chart?.jd ?? 0, atBirth: atBirth) ?? [] }

    /// Go to a step of the walk-through: the desk opens the workspace, picks what the step speaks of and
    /// brings its card into view. `nil` ends the walk-through and leaves the desk where it stands.
    func tour(to index: Int?) {
        guard let index, tourSteps.indices.contains(index) else { tourAt = nil; glow = []; return }
        // the steps are read at the birth, except the one that lays the present sky over it
        let step = tourSteps[index]
        tourAt = index
        workspace = step.workspace
        if step.now { goNow() } else if !atBirth { goBirth() }
        pick = step.pick
        glow = step.glow
        if let card = step.card { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.showCard = card } }
    }
}

/// The walk-through's voice: it stands at the head of the inspector while the desk shows what it speaks of.
struct TourPanel: View {
    @EnvironmentObject var store: Store
    /// where the buttons stand in the window: read by the click witness (`--probe-tour`)
    static var spots: [String: CGRect] = [:]

    var body: some View {
        let steps = store.tourSteps
        if let at = store.tourAt, steps.indices.contains(at) {
            let step = steps[at]
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("Walk-through · \(at + 1) of \(steps.count)").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("End") { store.tour(to: nil) }.buttonStyle(.link).font(.caption).background(GeometryReader { geo in let place = geo.frame(in: .global); Color.clear.onAppear { TourPanel.spots["end"] = place }.onChanged(of: place) { TourPanel.spots["end"] = geo.frame(in: .global) } }).help("Close the walk-through and stay where the desk stands")
                }
                ProgressView(value: Double(at + 1), total: Double(steps.count)).tint(.accentColor)
                Text(step.title).font(.title3).fontWeight(.semibold)
                Text(step.words).fixedSize(horizontal: false, vertical: true)
                if store.familiar, !step.detail.isEmpty { Text(step.detail).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
                Label(step.tryIt, systemImage: "hand.point.up.left").font(.callout).foregroundStyle(Color.accentColor).fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Back") { store.tour(to: at - 1) }.disabled(at == 0).background(GeometryReader { geo in let place = geo.frame(in: .global); Color.clear.onAppear { TourPanel.spots["back"] = place }.onChanged(of: place) { TourPanel.spots["back"] = geo.frame(in: .global) } })
                    Button(at == steps.count - 1 ? "Finish" : "Next") { store.tour(to: at == steps.count - 1 ? nil : at + 1) }.keyboardShortcut(.defaultAction).background(GeometryReader { geo in let place = geo.frame(in: .global); Color.clear.onAppear { TourPanel.spots["next"] = place }.onChanged(of: place) { TourPanel.spots["next"] = geo.frame(in: .global) } })
                    Spacer()
                    if !store.familiar, !step.detail.isEmpty {
                        Button("More") { store.explanation = Explanation(title: step.title, group: "For the familiar reader", lines: [step.detail]) }.buttonStyle(.link).font(.caption)
                            .help("The finer point of this step")
                    }
                }
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.1))
        }
    }
}

extension Help {
    /// How a card's numbers are reached and which conventions it follows: for a reader who knows the tradition.
    static func method(_ id: String) -> String? {
        if id == "chart:0" { return "Whole-sign houses from the lagna's sign. Sidereal positions under this chart's ayanamsa, Rahu and Ketu by this chart's node setting. Tints show full graha drishti by sign." }
        if id == "moon" { return "Chandra lagna: the same signs with the Moon's sign as the first house." }
        if id.hasPrefix("chart:") { return "One of Parashara's sixteen vargas: each graha is placed by the part of its sign it occupies. Houses are whole signs from the varga lagna." }
        switch id {
        case "grahas": return "Degrees within the sign; nakshatra and pada; lords as rasi · star · sub, the sub by the Vimshottari division of the star. C marks a combust graha. Motion is in degrees a day; a negative value is retrograde."
        case "rashi-meanings", "bhava-classes", "bhava-karakas", "bhava-meanings", "graha-meanings": return "After Light on Life, chapters 4 and 6. Houses are whole signs counted from the lagna. Every karaka of a house is weighed as a limb in the house's judgement: the 4th and the 10th have four, the 6th and the 9th two."
        case "houses": return "Whole-sign houses. Aspects are full graha drishti. Bindus are the sign's total in the sarvashtakavarga."
        case "reading": return "Sentences drawn from the same figures the other cards show; nothing here is computed apart from them."
        case "shadbala": return "The six strengths follow B.V. Raman's Graha and Bhava Balas. Planetary war is left out. Cheshta and drik bala can differ from other programs by a few virupas. The last row is the ratio to the required minimum."
        case "ashtakavarga": return "Bhinnashtakavarga for each of the seven grahas and their sum, 337 bindus over the twelve signs, shown before any reduction."
        case "bala-sky", "bala-table", "bala-keys", "bala-relations", "bala-charts": return "The rules follow Light on Life (de Fouw and Svoboda), chapters 4 and 9. Friendship is the natural relationship of its table 4.3. Combustion uses its table 9.1 and states the distance from the Sun, since the closer a graha stands the stronger the combustion. The Moon is read by its light: new within 30° of the Sun, dark within 72° of it, full within 30° of the full point, bright between. A birth within about half a day of an exact new or full Moon is an eclipse when the lights stand close enough to a node: within 12°30′ for a lunar eclipse, 18°30′ for a solar one. Combustion is graded by degrees from the Sun: totally within 3°, seriously within 6°, generally within 9°. Planetary war goes to the higher latitude. The nodes are exalted in Vrischika and debilitated in Vrishabha."
        case "avasthas": return "Baladi by degree and the sign's parity; Jagradadi and Deeptadi by dignity, friendship and combustion."
        case "yogas": return "Rules in their commonly taught forms from Phaladipika and Parashara. Benefics are Mercury, Jupiter and Venus; aspects are full graha drishti by sign. Where schools differ, both forms are listed with the rule in the name."
        case "aspects": return "Full graha drishti by whole sign: the 7th for all; Mars also the 4th and 8th, Jupiter the 5th and 9th, Saturn the 3rd and 10th."
        case "timeline", "dashas": return "Vimshottari from the Moon's nakshatra, with a year of 365.25 days."
        case "dasha-context": return "The running lords at the time bar's moment, read by the houses they rule and occupy from the lagna, with the slow grahas' transits beside them."
        case "other-dashas": return "Further nakshatra dashas, each counted from the Moon's nakshatra by its own order and span of years. Several are conditional in the texts; the card says when a condition applies."
        case "events": return "Each date is set against the Vimshottari periods running that day, as published readings do when testing a chart."
        case "karakas": return "Seven chara karakas ranked by degrees within the sign."
        case "arudhas": return "Each pada is found by counting from the house to its lord and as far again."
        case "chara-dasha": return "Jaimini's chara dasha of signs, as taught by K.N. Rao."
        case "kp-grahas", "kp-cusps", "kp-houses", "kp-planets": return "Krishnamurti Paddhati: the KP ayanamsa, Placidus cusps, and significators graded by star lord and occupancy."
        case "panchanga": return "Weekday counted from sunrise; hours as twelfths of the day and of the night; gandanta within 3°20′ of a water-fire joint."
        case "dina": return "The day's five limbs with the moment each ends, the ground for choosing a time."
        case "gochara": return "Favourable places from the Moon after Phaladipika 26, with vedha and the giving third of the sign."
        case "transits": return "The sky of the time bar's moment under this chart's ayanamsa, with houses counted from the birth lagna and the birth Moon."
        case "transit-dates": return "Sign changes and stations found by search, each to within a minute."
        case "match": return "Ashtakoota by the standard tables, 36 points, counted from the bride's Moon to the groom's."
        case "annual": return "Tajika Varshaphal: the sidereal return of the Sun to its birth longitude, cast for the birth place. Muntha moves one sign a year from the birth lagna."
        case "edges": return "Placements close to the edge of a sign or nakshatra, with the change of birth time or ayanamsa that would carry each across."
        case "birth": return "A birth before standard time zones is entered with its local mean time as a fixed offset from Greenwich."
        default: return nil
        }
    }

    /// Something to do on a card, so its help is tried and not only read.
    static func tryIt(_ id: String) -> String {
        if id.hasPrefix("chart:") || id == "moon" { return "Rest the pointer on a graha or a sign; click to keep it. The arrows at the top right draw the chart larger or smaller." }
        switch id {
        case "yogas": return "Rest the pointer on a yoga to light its grahas in every chart; click it for its rule and meaning."
        case "grahas", "shadbala", "ashtakavarga", "avasthas", "aspects", "transits", "kp-grahas": return "Rest the pointer on a row to light that graha on every card. Click a column heading for what it measures."
        case "houses": return "Click a row to pick that house everywhere; under the row it is judged by its three limbs: the house, its lord and its karaka."
        case "timeline", "dashas", "other-dashas", "chara-dasha": return "Click a period to read about it, and use Go there to move the whole desk to its start."
        case "dasha-context", "transit-dates": return "Step the time bar and watch this card follow the moment."
        case "glossary": return "Type any word. Each entry says what it is and what it is in the open chart."
        case "guide": return "Press Start the walk-through: the desk shows each step in this chart as it is explained."
        case "events": return "Add a dated event of the life and read which periods were running that day."
        case "match": return "Choose the second chart, then click a measure to read what it looks at."
        default: return "Rest the pointer on anything named here; click to keep it. Drag the card's title onto another card to move it."
        }
    }

    /// A card explained in one place: what it shows, how it is reached, and what to try.
    static func about(card id: String) -> Explanation {
        Explanation(title: Catalog.info(id).title, group: "About this card",
                    lines: [card(id)] + (method(id).map { ["How it is reached: " + $0] } ?? []) + ["Try: " + tryIt(id)])
    }
}
