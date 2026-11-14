import AppKit
import SwiftUI

@main
struct FormJyotishApp: App {
    @StateObject private var store = Store()
    @StateObject private var updater = Updater()

    init() {
        let arguments = CommandLine.arguments
        // a newer build fetched during the last run takes this one's place before anything else happens
        if arguments.contains("--save-public") { print("public charts added: \(PublicCharts.saveAll())"); exit(0) }
        if arguments.contains("--update-helper") { UpdateHelper.run(); exit(0) }
        // `FormJyotish --entry-check`: dates and times as people type them, each read to the one form the app writes
        // `FormJyotish --house-check`: the judgement of the twelve houses on a public chart, held to what was read and checked by hand
        if arguments.contains("--house-check") {
            let defaults = UserDefaults.standard
            let engine = Engine(root: URL(fileURLWithPath: defaults.string(forKey: "enginePath") ?? Engine.defaultRoot), kernel: URL(fileURLWithPath: defaults.string(forKey: "kernelPath") ?? Engine.defaultKernel))
            guard let birth = PublicCharts.all.first(where: { $0.key == "einstein" })?.birth, let chart = try? engine.chart(for: birth, node: birth.node ?? "mean", ayanamsa: birth.ayanamsa ?? "lahiri") else { print("house check: the chart could not be read"); exit(1) }
            var held = 0, asked = 0
            func hold(_ what: String, _ truth: Bool) { asked += 1; if truth { held += 1 } else { print("house check: \(what) does not hold") } }
            for house in 1...12 {
                let limbs = chart.limbs(ofHouse: house)
                hold("house \(house) has a house limb and a lord limb", limbs.first?.id == "house" && limbs.contains { $0.id == "lord" })
                hold("house \(house) has a karaka limb unless its lord is its karaka", limbs.contains { $0.id == "karaka" } != (chart.lord(ofHouse: house) == Lore.bhavaKarakas[house - 1].code))
                hold("house \(house) says where its limbs stand", !chart.confluence(ofHouse: house).isEmpty)
            }
            // Mithuna rises: the 7th is Dhanu, its lord Jupiter stands in the 9th, its karaka Venus is exalted in the 10th
            let seventh = chart.limbs(ofHouse: 7)
            hold("the 7th lord is Jupiter", seventh.first { $0.id == "lord" }?.graha == "Ju")
            hold("Venus as karaka of the 7th is supported", (seventh.first { $0.id == "karaka" }?.leaning ?? 0) > 0)
            hold("Saturn's aspect is named on the 7th house", seventh[0].strains.contains { $0.hasPrefix("Saturn") })
            hold("the 2nd house has its limbs agree in asking more", chart.limbs(ofHouse: 2).allSatisfy { $0.leaning < 0 })
            hold("the Moon is waning and counts as a malefic", !chart.benefic("Mo"))
            hold("Jupiter's dispositor is Saturn", chart.graha("Ju").flatMap { chart.dispositor(of: $0) }?.id == "Sa")
            let rows = chart.gochara(sky: chart)
            hold("the count from the Moon has nine rows and the Moon is 1st from itself", rows.count == 9 && rows.first { $0.id == "Mo" }?.fromMoon == 1)
            hold("a favourable place always names its vedha", rows.allSatisfy { $0.favourable == ($0.vedhaPlace != nil) })
            // 14 March 1879 was a Friday; at 11:30 the sixth hour of the day ran, which on a Friday is the hour of Mars
            let time = chart.varaAndHora(zoneHours: birth.zoneHours ?? 0)
            hold("the birth weekday is Friday", time?.weekday == 5)
            hold("the birth hour is the hour of Mars", time?.hora == "Ma")
            let limbs5 = chart.panchanga(zoneHours: birth.zoneHours ?? 0)
            hold("the panchanga has its seven rows", limbs5.map(\.id) == ["Vara", "Hora", "Tithi", "Karana", "Yoga", "Nakshatra", "Gandanta"])
            hold("the tithi is Krishna Saptami", limbs5.first { $0.id == "Tithi" }?.value.hasPrefix("Krishna Saptami, until Fri ") == true)
            hold("the Sun in the 10th has directional strength", chart.graha("Su").map { chart.finer($0).supports.contains { $0.hasPrefix("Directional strength") } } == true)
            hold("Jupiter in the 9th is without the directional strength it has in the 1st, and is not marked weak for it", chart.graha("Ju").map { !chart.finer($0).strains.contains { $0.hasPrefix("Without directional") } } == true)
            hold("Mercury's period names its yogas and its dispositor", chart.activation(of: "Me").contains { $0.hasPrefix("It takes part in") } && chart.activation(of: "Me").contains { $0.hasPrefix("Its dispositor Jupiter") })
            hold("Rahu's period is read through its sign lord Saturn", chart.activation(of: "Ra").first?.contains("sign lord Saturn") == true)
            hold("Mercury and Mars read together end with the count from the dasha lord", chart.joint("Me", "Ma").last?.hasPrefix("Counted from Mercury, Mars stands in the 11th") == true)
            hold("a graha read with itself gives nothing", chart.joint("Me", "Me").isEmpty)
            hold("each of the seven carries its latitude and whether it nears the Sun", chart.grahas.prefix(7).allSatisfy { $0.lat != nil && $0.nearing != nil } && abs(chart.graha("Mo")?.lat ?? 9) < 5.4)
            hold("the running tithi ends after the birth and within its span", chart.day.tithi_end.map { $0 > chart.jd && $0 - chart.jd < 1.2 } == true && chart.day.karana_end.map { $0 <= (chart.day.tithi_end ?? 0) + 0.0001 } == true)
            hold("the Moon in Jyeshtha is read in a sharp nakshatra", chart.panchanga(zoneHours: birth.zoneHours ?? 0).first { $0.id == "Nakshatra" }?.words.contains("sharp (tikshna) nakshatra: the Moon there inclines") == true)
            hold("a later day read against the birth names the rising sign and what its lord serves", chart.panchanga(zoneHours: 0, natal: chart).first { $0.id == "Lagna" }?.words.contains("under its rising sign") == true)
            // the planetary war Light on Life reads on the evening of 20 April 1889: the sky gives Venus the higher latitude
            if let war = try? engine.chart(julianDay: 2411113.2347, latitude: 48.25, longitude: 13.03, node: "mean", ayanamsa: "lahiri", zoneHours: 0.87), let venus = war.graha("Ve"), let mars = war.graha("Ma") {
                hold("in the war of 1889 Venus prevails by latitude, against the lower-longitude rule", war.finer(venus).supports.contains { $0.contains("so Venus prevails; the lower-longitude rule") } && war.finer(mars).strains.contains { $0.contains("Venus 6.3° north, so Venus prevails") })
            } else { hold("the sky of 1889 could be read", false) }
            hold("the 7th is read as a Bhadra tithi", chart.panchanga(zoneHours: birth.zoneHours ?? 0).first { $0.id == "Tithi" }?.words.contains("The 7th is a Bhadra tithi") == true)
            hold("a later day names the place its rising sign is read from", chart.panchanga(zoneHours: 0, natal: chart, place: "Ubud").first { $0.id == "Lagna" }?.words.hasPrefix("The sign rising at Ubud;") == true)
            // what Light on Life reads in Einstein's chart, under Lahiri as the book counts it
            if let book = try? engine.chart(julianDay: 2407422.9514, latitude: 48.4, longitude: 10.0, node: "mean", ayanamsa: "lahiri", zoneHours: 0.667), let mercury = book.graha("Me"), let venus = book.graha("Ve"), let mars = book.graha("Ma") {
                let names = Set(book.yogas.map(\.name))
                hold("the yogas the book reads in Einstein's chart are found", ["Budhaditya yoga", "Neecha-bhanga raja yoga", "Maha-parivartana yoga", "Pravrajya yoga", "Saraswati yoga"].allSatisfy { names.contains($0) })
                hold("the primary factors name Mercury debilitated and combust, and Venus exalted", book.keyFactors(mercury).primaryWeakness.first == "Debilitated" && book.keyFactors(mercury).primaryWeakness.contains { $0.contains(" combust, ") } && book.keyFactors(venus).primaryStrength.contains("Exalted"))
                hold("Einstein was not born on an eclipse, and no planetary war stands in his chart", book.grahas.prefix(2).allSatisfy { book.eclipsed($0) == nil } && book.grahas.allSatisfy { book.war(of: $0) == nil })
                if let lunar = try? engine.chart(julianDay: 2451564.697, latitude: 28.6, longitude: 77.2, node: "mean", ayanamsa: "lahiri", zoneHours: 5.5), let moon = lunar.graha("Mo") {
                    hold("a birth at the total lunar eclipse of 21 January 2000 is read as born on a lunar eclipse, the Moon full", lunar.eclipsed(moon)?.kind.contains("lunar eclipse") == true && lunar.moonFull && lunar.keyFactors(moon).primaryWeakness.contains { $0.hasPrefix("Born on ") })
                    print("seen at the lunar eclipse: " + (lunar.eclipsed(moon).map { "\($0.kind) by \($0.node)" } ?? "none"))
                }
                if let solar = try? engine.chart(julianDay: 2451401.96, latitude: 48.1, longitude: 11.6, node: "mean", ayanamsa: "lahiri", zoneHours: 2), let sun = solar.graha("Su") {
                    hold("a birth at the solar eclipse of 11 August 1999 is read as born on a solar eclipse, the Moon new", solar.eclipsed(sun)?.kind.contains("solar eclipse") == true && solar.moonNew)
                    print("seen at the solar eclipse: " + (solar.eclipsed(sun).map { "\($0.kind) by \($0.node)" } ?? "none"))
                }
                hold("the 4th house is judged with all four of its karakas: Mercury its lord, then the Moon, Venus and Mars", book.limbs(ofHouse: 4).count == 5 && book.limbs(ofHouse: 4).last?.graha == "Ma")
                hold("the 6th is a trik-sthana and an upachaya of artha, the 5th a trikona of dharma", Lore.houseClasses(6).map(\.name) == ["Trik", "Upachaya", "Apoklima"] && Lore.aim(of: 6) == "Artha" && Lore.aim(of: 5) == "Dharma" && Lore.houseClasses(5).first?.name == "Trikona")
                hold("the nine grahas are counted across the four aims", (0..<4).map { book.grahas(inAim: $0).count }.reduce(0, +) == 9)
                print("seen in the four aims: " + (0..<4).map { "\(Lore.aimsOfLife[$0].name) \(book.grahas(inAim: $0).map(\.id).joined(separator: " "))" }.joined(separator: "; "))
                hold("the desks the book teaches come first and the additions last", Array(Store.workspaces.suffix(4)).allSatisfy(Store.additions.contains) && Store.workspaces.prefix(7).allSatisfy { !Store.additions.contains($0) })
                hold("on every desk the book's cards stand before the additions", Store.standardLayout.values.allSatisfy { cards in let first = cards.firstIndex(where: Catalog.additions.contains) ?? cards.count; return cards[first...].allSatisfy { Catalog.additions.contains($0) || $0.hasPrefix("chart:") || ["moon", "dasha-context"].contains($0) } })
                hold("the ayanamsa at Einstein's birth is near 22 degrees", abs(book.ayanamsa - 22.1) < 0.3)
                if let war = try? engine.chart(julianDay: 2411113.2347, latitude: 48.25, longitude: 13.03, node: "mean", ayanamsa: "lahiri", zoneHours: 0.87), let v = war.graha("Ve"), let m = war.graha("Ma"), let mv = war.magnitude(v), let mm = war.magnitude(m) {
                    hold("in the war of 1889 Venus outshines Mars as well as standing higher, and both magnitudes agree with JPL Horizons (-4.276, 1.449) within 0.05", abs(mv + 4.276) < 0.05 && abs(mm - 1.449) < 0.05 && war.brightnessLine(v, m).contains("both tests agree"))
                    print(String(format: "seen in the war of 1889: Venus magnitude %.2f, Mars magnitude %.2f", mv, mm))
                }
                hold("Einstein's Moon is a waning gibbous turning to its last quarter", ["waning gibbous", "last quarter"].contains(book.moonPhase))
                hold("Simha rises head first, Mesha back first, Meena both ways; Karka is fruitful and Simha barren", Lore.rising(4).hasPrefix("head") && Lore.rising(0).hasPrefix("back") && Lore.rising(11).hasPrefix("rising both") && Lore.fruitful(3) == "fruitful" && Lore.fruitful(4) == "barren")
                hold("Venus exalted in Meena, which rises both ways, takes no rising line; Jupiter in head-rising Kumbha grows more benefic", !book.factors(for: venus).supports.contains { $0.contains("-rising rashi") } && book.graha("Ju").map { book.factors(for: $0).supports.contains { $0.hasPrefix("In a head-rising rashi") } } == true)
                hold("Guru-Chandala is marked as outside the textbook and Gaja-Kesari is not", Lore.yogaBeyondBook("Guru-Chandala yoga") && !Lore.yogaBeyondBook("Gaja-Kesari yoga"))
                hold("a combustion states its distance from the Sun", book.factors(for: mercury).strains.contains { $0.hasPrefix("Combust, ") && $0.contains("° from the Sun") })
                hold("the Moon is read by its light and never as combust", book.graha("Mo").map { m in !book.factors(for: m).strains.contains { $0.hasPrefix("Combust") } && (book.factors(for: m).supports + book.factors(for: m).strains).contains { $0.hasPrefix("Bright Moon (waning, Krishna Saptami, 99° from the Sun)") } } == true)
                hold("friendship is the natural one: the Sun in Meena is the guest of its friend Jupiter", book.graha("Su").map { book.keyFactors($0).secondaryStrength.contains("Friend's sign (Jupiter)") } == true)
                hold("Mercury and Jupiter have directional strength in the 1st, and Venus is without it in the 10th", Lore.digBala["Me"] == 1 && Lore.digBala["Ju"] == 1 && !book.keyFactors(venus).primaryStrength.contains("Dig bala"))
                hold("Mercury and Jupiter have directional strength in the 1st, and two of the four in Meena are combust", mercury.status == "Debil." && mercury.combust == true && book.house(ofSign: mercury.sign) == 10 && book.grahas.filter { $0.sign == 11 && $0.combust == true }.count == 2)
                hold("Venus is exalted in the 10th and Mars, lord of the Moon's sign, is exalted", venus.status == "Exalt." && book.house(ofSign: venus.sign) == 10 && mars.status == "Exalt.")
                hold("the lagna stands in Ardra, within three minutes of Punarvasu", book.asc.nak == 5 && 20 - book.asc.deg < 0.75 && book.asc.sign == 2)
                hold("Jupiter aspects the lagna", book.aspects[4].contains(book.asc.sign))
                hold("Malavya recurs from all three lagnas, as the book counts it", book.yogas.contains { $0.name == "Malavya yoga" && $0.why.contains("recurs from all three lagnas (a trine gives the extended form)") })
                hold("Mercury's cancellation is a raja yoga and the Moon's is not", book.yogas.contains { $0.name == "Neecha-bhanga raja yoga" && $0.grahas == ["Me"] } && book.yogas.contains { $0.name == "Neecha-bhanga" && $0.grahas == ["Mo"] })
                hold("the first dasha, Mercury's, ends about 12 December 1888", book.dasha.first.map { $0.lord == "Me" && abs($0.end - 2410983.5) < 3 } == true)
                hold("the Sun has directional strength in the 10th", book.graha("Su").map { book.finer($0).supports.contains { $0.hasPrefix("Directional strength") } } == true)
            } else { hold("Einstein's chart under Lahiri could be read", false) }
            // skies found by scanning 2020: a Kala-sarpa yoga, and a mahapurusha yoga recurring from all three lagnas
            if let sarpa = try? engine.chart(julianDay: 2458904.26, latitude: 28.6139, longitude: 77.209, node: "mean", ayanamsa: "lahiri", zoneHours: 5.5), let yoga = sarpa.yogas.first(where: { $0.name == "Kala-sarpa yoga" }) {
                let words = sarpa.yogaConditions(yoga) ?? ""
                print("seen: " + words)
                hold("a Kala-sarpa yoga says which way it lies and where it gathers", (words.contains("anuloma") || words.contains("viloma")) && words.contains("Its matters gather in the houses"))
            } else { hold("the Kala-sarpa sky of 2020 could be read", false) }
            if let three = try? engine.chart(julianDay: 2458859.23, latitude: 28.6139, longitude: 77.209, node: "mean", ayanamsa: "lahiri", zoneHours: 5.5) {
                let whys = three.yogas.filter { $0.group == "Mahapurusha" }.map { $0.name + ": " + $0.why }
                print("seen: " + whys.joined(separator: " | "))
                hold("a mahapurusha yoga says it recurs from all three lagnas", whys.contains { $0.contains("recurs from all three lagnas") })
            } else { hold("the three-lagna sky of 2020 could be read", false) }
            for other in PublicCharts.all {
                guard let b = Optional(other.birth), let c = try? engine.chart(for: b, node: b.node ?? "mean", ayanamsa: b.ayanamsa ?? "lahiri") else { continue }
                for g in c.grahas { if c.war(of: g) != nil { let f = c.finer(g); print("seen in \(other.key): " + (f.supports + f.strains).filter { $0.contains("planetary war") }.joined()) } }
                for g in c.grahas where g.combust == true { print("seen in \(other.key): \(g.id) " + (c.factors(for: g).strains.first { $0.hasPrefix("Combust") } ?? "")) }
            }
            hold("the tithi limb names when it ends", chart.panchanga(zoneHours: birth.zoneHours ?? 0).first { $0.id == "Tithi" }?.value.contains(", until ") == true)
            print("house check: \(held) of \(asked) hold")
            exit(held == asked ? 0 : 1)
        }
        if arguments.contains("--entry-check") {
            let dates: [(String, String?)] = [("1971-03-11", "1971-Mar-11"), ("1971-3-11", "1971-Mar-11"), ("11 Mar 1971", "1971-Mar-11"), ("March 11, 1971", "1971-Mar-11"), ("11.3.1971", "1971-Mar-11"),
                                             ("13/3/1971", "1971-Mar-13"), ("3/13/1971", "1971-Mar-13"), ("1971/03/11", "1971-Mar-11"), ("1971-Mar-11", "1971-Mar-11"), ("1971-dec-01", "1971-Dec-01"), ("31 Feb 1971", nil), ("11 Mar 71", nil), ("soon", nil)]
            let times: [(String, String?)] = [("02:50", "02:50:00"), ("2:50", "02:50:00"), ("2:50 am", "02:50:00"), ("2.50pm", "14:50:00"), ("0250", "02:50:00"), ("14", "14:00:00"), ("12 am", "00:00:00"),
                                             ("12:30 pm", "12:30:00"), ("09:15:30", "09:15:30"), ("25:00", nil), ("13 pm", nil), ("noonish", nil)]
            var held = 0
            for (typed, want) in dates { let got = Birth(date: typed).writtenDate; if got == want { held += 1 } else { print("date \(typed): read \(got ?? "nothing"), expected \(want ?? "nothing")") } }
            for (typed, want) in times { let got = Birth(time: typed).writtenTime; if got == want { held += 1 } else { print("time \(typed): read \(got ?? "nothing"), expected \(want ?? "nothing")") } }
            print("entry check: \(held) of \(dates.count + times.count) read as expected")
            exit(held == dates.count + times.count ? 0 : 1)
        }
        Updater.waitForPredecessor(arguments)
        if !arguments.contains("--report") && !arguments.contains("--match-check") {
            Updater.installStagedAndRelaunch()
            // The last run did not end cleanly (a force quit, a window that stopped answering): before any
            // window opens, ask for a newer build and take it. A build that cannot show itself still heals.
            if UserDefaults.standard.bool(forKey: "running"), case .staged = UpdateHelper.runApart(seconds: 200) { Updater.installStagedAndRelaunch() }
        }
        if arguments.contains("--match-check") { print("match check: \(Match.check()) (23.5 expected)"); exit(Match.check() == 23.5 ? 0 : 1) }
        if let flag = arguments.firstIndex(of: "--report"), arguments.count > flag + 1 {
            Self.writeReport(to: arguments[flag + 1], arguments: arguments)
        }
        // Run from `swift run` there is no bundle, so the process asks to be a regular app with a window.
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    /// `FormJyotish --report out.pdf [--public key] [--ayanamsa lahiri|truecitra|raman] [--node mean|true]`:
    /// write the report of a public chart, or of the first saved chart, without opening a window, then leave.
    private static func writeReport(to path: String, arguments: [String]) -> Never {
        func option(_ name: String) -> String? {
            arguments.firstIndex(of: "--" + name).flatMap { arguments.count > $0 + 1 ? arguments[$0 + 1] : nil } ?? UserDefaults.standard.string(forKey: name)
        }
        let defaults = UserDefaults.standard
        let engine = Engine(root: URL(fileURLWithPath: defaults.string(forKey: "enginePath") ?? Engine.defaultRoot),
                            kernel: URL(fileURLWithPath: defaults.string(forKey: "kernelPath") ?? Engine.defaultKernel))
        // with --public <key> the report is of that public chart, and no saved chart is read
        let known = arguments.firstIndex(of: "--public").flatMap { arguments.count > $0 + 1 ? arguments[$0 + 1] : nil }.flatMap { key in PublicCharts.all.first { $0.key == key }?.birth }
        // with --example the report is of the sample chart, an arbitrary moment and place
        let example = arguments.contains("--example") ? Birth(name: "Sample: New Delhi 2000", date: "2000-01-01", time: "17:30:00", zone: "Asia/Kolkata", place: "New Delhi, India", latitude: 28.6139, longitude: 77.209) : nil
        guard let birth = known ?? example ?? Store().births.first else { print("no saved chart"); exit(1) }
        do {
            let node = birth.node ?? option("node") ?? "mean", ayanamsa = birth.ayanamsa ?? option("ayanamsa") ?? "lahiri"
            let chart = try engine.chart(for: birth, node: node, ayanamsa: ayanamsa)
            let transit = try? engine.chart(julianDay: Date().timeIntervalSince1970 / 86400 + 2440587.5, latitude: birth.latitude, longitude: birth.longitude,
                                            node: node, ayanamsa: ayanamsa, zoneHours: birth.zoneHours ?? 0)
            guard Report(birth: birth, chart: chart, transit: transit).write(to: URL(fileURLWithPath: path)) else { print("the report could not be written to \(path)"); exit(1) }
            print("report written to \(path)")
            exit(0)
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    /// `FormJyotish --probe-tabs`: press each workspace tab with a real mouse event sent to the window, and say
    /// whether the workspace followed. A witness that the tabs answer clicks, not only accessibility presses.
    private func probeTabs() {
        makeKey(after: 1)
        // with --probe-banner the update banner stands above the tabs, as it does after an update is fetched
        if CommandLine.arguments.contains("--probe-banner") { DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { updater.state = .ready(999) } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) else { print("probe: no window"); exit(1) }
            var held = 0
            func press(_ index: Int) {
                guard index < Store.workspaces.count else { print("probe: \(held) of \(Store.workspaces.count) tabs answered a click"); exit(held == Store.workspaces.count ? 0 : 1) }
                let name = Store.workspaces[index]
                guard let spot = WorkspaceTabs.spots[name] else { print("probe: \(name) reported no place"); press(index + 1); return }
                // SwiftUI counts from the window's top edge once the window has settled; the window counts from its bottom
                let point = NSPoint(x: spot.midX, y: window.frame.height - spot.midY)
                for kind in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                    if let event = NSEvent.mouseEvent(with: kind, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1) { window.sendEvent(event) }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    let hit = window.contentView?.hitTest(point)
                    print("probe: \(name) at \(Int(spot.midX)),\(Int(spot.midY)) -> workspace \(store.workspace)\(store.workspace == name ? "" : "  MISSED, hit \(hit.map { String(describing: type(of: $0)) } ?? "nothing")")")
                    if store.workspace == name { held += 1 }
                    press(index + 1)
                }
            }
            press(0)
        }
    }

    /// `FormJyotish --snapshot out.png`: after the window has settled, write what it shows as a picture and
    /// leave. With `--public`, `--workspace`, `--look-up` it shows a new view without anyone clicking.
    private func snapshot(to path: String) {
        let arguments = CommandLine.arguments
        func value(_ name: String) -> String? { arguments.firstIndex(of: name).flatMap { arguments.count > $0 + 1 ? arguments[$0 + 1] : nil } }
        // --size 1600x900 sets the window's size; --focus Ju rests the pointer on a graha; --glow Ju,Mo lights several;
        // --tour 2 opens that step of the walk-through; --about yogas opens a card's explanation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let size = value("--size")?.split(separator: "x").compactMap({ Double($0) }), size.count == 2, let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) {
                window.setFrame(NSRect(x: window.frame.minX, y: window.frame.minY, width: size[0], height: size[1]), display: true)
            }
            if let level = value("--guidance") { store.guidance = level }
            if let step = value("--tour").flatMap({ Int($0) }) { store.tour(to: step - 1) }
            if value("--about") != nil { store.explanation = Help.about(card: value("--about") ?? "") }
            if let code = value("--focus") { store.hover = .graha(code) }
            // --only-card gochara shows that card alone in the workspace (a snapshot writes no layout)
            if let card = value("--only-card") { store.layout[store.workspace] = [card] }
            // --here "name|latitude|longitude|zone" reads the later sky from that place
            if let parts = value("--here")?.split(separator: "|").map(String.init), parts.count == 4, let latitude = Double(parts[1]), let longitude = Double(parts[2]) { store.here = Store.Here(place: parts[0], latitude: latitude, longitude: longitude, zone: parts[3]) }
            if arguments.contains("--now") { store.goNow() }
            if let house = value("--pick-house").flatMap({ Int($0) }), let chart = store.chart { store.pick = .sign(chart.sign(ofHouse: house)) }
            if let codes = value("--glow") { store.glow = codes.split(separator: ",").map(String.init) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }), let view = window.contentView, let shot = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { print("snapshot: no window"); exit(1) }
            view.cacheDisplay(in: view.bounds, to: shot)
            guard let data = shot.representation(using: .png, properties: [:]), (try? data.write(to: URL(fileURLWithPath: path))) != nil else { print("snapshot: could not write \(path)"); exit(1) }
            print("snapshot written to \(path)")
            exit(0)
        }
    }

    /// `FormJyotish --probe-tour`: start the walk-through, press Next, Next, Back and End with real mouse events
    /// sent to the window, and say whether the step and the workspace followed each press.
    private func probeTour() {
        makeKey(after: 1.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { store.tour(to: 0) }
        let presses: [(button: String, step: Int?)] = [("next", 1), ("next", 2), ("next", 3), ("next", 4), ("next", 5), ("next", 6), ("back", 5), ("end", nil)]
        var held = 0
        func press(_ index: Int) {
            guard index < presses.count else { print("probe: \(held) of \(presses.count) walk-through presses answered"); exit(held == presses.count ? 0 : 1) }
            let (button, step) = presses[index]
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }), let spot = TourPanel.spots[button] else { print("probe: \(button) reported no place"); exit(1) }
            let point = NSPoint(x: spot.midX, y: window.frame.height - spot.midY)
            func event(_ kind: NSEvent.EventType) -> NSEvent? {
                NSEvent.mouseEvent(with: kind, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
            }
            // a button follows the mouse in its own loop until the release arrives, so the release waits in the
            // queue before the press is sent
            if let up = event(.leftMouseUp), let down = event(.leftMouseDown) { NSApp.postEvent(up, atStart: false); window.sendEvent(down) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                let ok = store.tourAt == step && (step == nil || store.workspace == store.tourSteps[step!].workspace)
                print("probe: \(button) -> step \(store.tourAt.map { String($0 + 1) } ?? "none"), workspace \(store.workspace), picked \(store.pick.map { String(describing: $0) } ?? "nothing")\(ok ? "" : "  MISSED")")
                if ok { held += 1 }
                press(index + 1)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { press(0) }
    }

    /// `FormJyotish --probe-table`: on Overview, click the Jupiter row and then the Nakshatra heading with real
    /// mouse events, and say whether the row was picked and the heading explained.
    private func probeTable() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { store.workspace = "Overview" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { store.showCard = "grahas" }
        // a heading that carries an explanation and stands inside the window now
        func heading() -> String? {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) else { return nil }
            return PickRow.spots.filter { $0.key.hasPrefix("heading:") && $0.value.midY > 120 && $0.value.midY < window.frame.height - 120 && $0.value.midX > 300 }.keys.sorted().first
        }
        func click(_ key: String) -> Bool {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }), let spot = PickRow.spots[key] else { print("probe: \(key) reported no place"); return false }
            let point = NSPoint(x: spot.midX, y: window.frame.height - spot.midY)
            print("probe: \(key) at \(Int(spot.midX)),\(Int(spot.midY)) of window \(Int(window.frame.width))x\(Int(window.frame.height)), scale \(store.textScale), key \(window.isKeyWindow), active \(NSApp.isActive), hit \(window.contentView?.hitTest(point).map { String(describing: type(of: $0)) } ?? "nothing")")
            func event(_ kind: NSEvent.EventType) -> NSEvent? {
                NSEvent.mouseEvent(with: kind, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
            }
            // inside a scrolling desk a tap is told from a drag by its release, which follows a moment later
            if let down = event(.leftMouseDown) { window.sendEvent(down) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { if let up = event(.leftMouseUp) { window.sendEvent(up) } }
            return true
        }
        // a click on a window that is not key only brings it forward, so the witness makes its window key first
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { NSApp.activate(ignoringOtherApps: true); NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil })?.makeKeyAndOrderFront(nil) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard NSApp.windows.contains(where: { $0.isKeyWindow }) else { print("probe: the window could not be made key, so no click was tried"); exit(2) }
            guard click("row:Ju") else { exit(1) }
            // the pick opens the inspector and the desk settles again before the next click can land
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let picked = store.pick?.graha == "Ju"
                print("probe: clicked the Jupiter row at \(PickRow.spots["row:Ju"].map { "\(Int($0.midX)),\(Int($0.midY))" } ?? "?") -> picked \(store.pick.map { String(describing: $0) } ?? "nothing")\(picked ? "" : "  MISSED")")
                guard let key = heading(), click(key) else { print("probe: no heading with an explanation stands in the window; places \(PickRow.spots.mapValues { "\(Int($0.midX)),\(Int($0.midY))" })"); exit(1) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    let explained = store.explanation != nil
                    print("probe: clicked the \(key.dropFirst(8)) heading -> explained \(store.explanation?.title ?? "nothing")\(explained ? "" : "  MISSED")")
                    exit(picked && explained ? 0 : 1)
                }
            }
        }
    }

    /// `FormJyotish --probe-palette`: open the palette on "shad", click "What is Shadbala?" with a real mouse
    /// event, and say whether the explanation came up.
    /// a click on a window that is not key only brings it forward, so each click witness makes its window key first
    private func makeKey(after seconds: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { NSApp.activate(ignoringOtherApps: true); NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil })?.makeKeyAndOrderFront(nil) }
    }

    private func probePalette() {
        store.paletteSeed = "shad"
        makeKey(after: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { store.paletteShown = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            guard NSApp.windows.contains(where: { $0.isKeyWindow }) else { print("probe: the window could not be made key, so no click was tried"); exit(2) }
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }), let spot = Palette.spots["what-Shadbala"] else { print("probe: the palette lists no What is Shadbala?"); exit(1) }
            let point = NSPoint(x: spot.midX, y: window.frame.height - spot.midY)
            for kind in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                if let event = NSEvent.mouseEvent(with: kind, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1) { window.sendEvent(event) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                print("probe: clicked What is Shadbala? at \(Int(spot.midX)),\(Int(spot.midY)) -> explained \(store.lookedUp ?? "nothing"), palette \(store.paletteShown ? "still open" : "closed")")
                exit(store.explanation?.title == "Shadbala" ? 0 : 1)
            }
        }
    }

    var body: some Scene {
        WindowGroup("Form Jyotish") {
            MainView()
                .environmentObject(store)
                .environmentObject(updater)
                .onAppear { updater.check(); if CommandLine.arguments.contains("--example") { store.ephemeral = true; store.addSample("New Delhi 2000", date: "2000-01-01", time: "17:30:00", zone: "Asia/Kolkata", place: "New Delhi, India", latitude: 28.6139, longitude: 77.209) }; if let i = CommandLine.arguments.firstIndex(of: "--public"), CommandLine.arguments.count > i + 1 { store.ephemeral = true; store.addPublic(CommandLine.arguments[i + 1]) }; if let i = CommandLine.arguments.firstIndex(of: "--show-card"), CommandLine.arguments.count > i + 1 { let card = CommandLine.arguments[i + 1]; DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { store.showCard = card } }; if let i = CommandLine.arguments.firstIndex(of: "--look-up"), CommandLine.arguments.count > i + 1 { store.lookedUp = CommandLine.arguments[i + 1] }; if let i = CommandLine.arguments.firstIndex(of: "--workspace"), CommandLine.arguments.count > i + 1, Store.workspaces.contains(CommandLine.arguments[i + 1]) { store.workspace = CommandLine.arguments[i + 1] }; if let i = CommandLine.arguments.firstIndex(of: "--snapshot"), CommandLine.arguments.count > i + 1 { snapshot(to: CommandLine.arguments[i + 1]) }; if CommandLine.arguments.contains("--probe-tabs") { probeTabs() }; if CommandLine.arguments.contains("--probe-palette") { probePalette() }; if CommandLine.arguments.contains("--probe-tour") { probeTour() }; if CommandLine.arguments.contains("--probe-table") { probeTable() } }
                .frame(minWidth: 1100, minHeight: 720)
        }
        .commands {
            CommandGroup(after: .appInfo) { Button("Check for Updates…") { updater.check(byHand: true) } }
        }
        Settings { SettingsView() }
    }
}
