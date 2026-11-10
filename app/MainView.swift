import SwiftUI
import UniformTypeIdentifiers

/// The window: saved charts at the side, a workspace of cards, the inspector, and one time bar under them all.
struct MainView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var updater: Updater

    var body: some View {
        NavigationSplitView {
            List(selection: $store.current) {
                ForEach(store.births) { birth in
                    Text(birth.name.isEmpty ? "Unnamed" : birth.name)
                        .tag(birth.id)
                        .contextMenu { Button("Delete", role: .destructive) { store.remove(birth.id) } }
                }
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 180)
            .toolbar { Button { store.add() } label: { Label("New chart", systemImage: "plus") } }
        } detail: {
            VStack(spacing: 0) {
                updateBanner
                HStack(spacing: 0) {
                    Workspace()
                    Divider()
                    Inspector().frame(width: 280)
                }
                Divider()
                TimeBar()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Workspace", selection: $store.workspace) { ForEach(Store.workspaces, id: \.self) { Text($0).tag($0) } }
                    .pickerStyle(.segmented).labelsHidden()
                    .help("Each workspace gathers the cards for one kind of reading")
            }
        }
        .overlay { if store.paletteShown { Palette(shown: $store.paletteShown, report: exportReport) } }
        .onAppear { store.readNatal() }
    }

    /// What the updater has to say: a newer build on its way, ready, or refused.
    @ViewBuilder private var updateBanner: some View {
        switch updater.state {
        case .idle: EmptyView()
        case .fetching(let build):
            banner("An update is available (build \(build)). Fetching it now…", action: nil)
        case .ready(let build):
            banner("Build \(build) is ready. It installs the next time Form Jyotish starts.", action: ("Restart now", { updater.restartNow() }))
        case .failed(let why):
            banner(why, action: ("Dismiss", { updater.state = .idle }))
        }
    }
    private func banner(_ words: String, action: (String, () -> Void)?) -> some View {
        HStack {
            Image(systemName: "arrow.down.circle").foregroundStyle(Color.accentColor)
            Text(words)
            Spacer()
            if let action { Button(action.0, action: action.1) }
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.12))
    }

    private func exportReport() {
        guard let birth = store.birth, let chart = store.chart else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(birth.name.isEmpty ? "Chart" : birth.name).pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let engine = store.engine, now = Date()
        let transit = store.sky ?? (try? engine.chart(julianDay: now.timeIntervalSince1970 / 86400 + 2440587.5, latitude: birth.latitude, longitude: birth.longitude,
                                                      node: store.node, ayanamsa: store.ayanamsa, zoneHours: Double(store.zone.secondsFromGMT(for: now)) / 3600))
        if Report(birth: birth, chart: chart, transit: transit).write(to: url) { NSWorkspace.shared.open(url) } else { store.problem = "The report could not be written to \(url.path)." }
    }
}

/// One bar moves the whole desk: the moment under view, or, while rectifying, the birth time itself.
struct TimeBar: View {
    @EnvironmentObject var store: Store
    @State private var step = 86400.0
    @State private var playing = false
    private let tick = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    private static let steps: [(name: String, seconds: Double)] = [("1 minute", 60), ("1 hour", 3600), ("1 day", 86400), ("1 week", 604800), ("1 month", 2629800), ("1 year", 31557600)]
    private static let fineSteps: [(name: String, seconds: Double)] = [("1 second", 1), ("10 seconds", 10), ("1 minute", 60), ("4 minutes", 240)]

    private var label: String {
        let format = Date.FormatStyle(date: .abbreviated, time: .standard, timeZone: store.zone)
        if store.rectifying {
            let shifted = store.birth?.moment?.addingTimeInterval(store.rectify)
            return "Birth time \(shifted?.formatted(format) ?? "")  (\(store.rectify >= 0 ? "+" : "−")\(Int(abs(store.rectify)) / 60)m \(Int(abs(store.rectify)) % 60)s)"
        }
        guard let moment = store.moment else { return "At the birth · \(store.birth?.moment?.formatted(format) ?? "")" }
        let age = store.chart.map { Vimshottari.span(days: moment.timeIntervalSince1970 / 86400 + 2440587.5 - $0.jd) } ?? ""
        return "\(moment.formatted(format)) · age \(age)"
    }

    var body: some View {
        let steps = store.rectifying ? Self.fineSteps : Self.steps
        VStack(spacing: 4) {
        if store.showHelp { Text(Help.timeBar).font(.footnote).foregroundStyle(.secondary).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading) }
        HStack(spacing: 8) {
            Button("Birth") { playing = false; store.goBirth() }.disabled(store.atBirth && !store.rectifying)
                .help("Return to the birth chart alone")
            Button("Now") { playing = false; store.goNow() }
                .help("Lay the present sky over the birth chart")
            Divider().frame(height: 18)
            Button { store.step(seconds: -step) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Step back").help("Step back by the chosen amount (⌘←)")
                .keyboardShortcut(.leftArrow, modifiers: .command)
            Picker("Step", selection: $step) { ForEach(steps, id: \.seconds) { Text($0.name).tag($0.seconds) } }.labelsHidden().frame(width: 120)
                .help("How far each step moves")
            Button { store.step(seconds: step) } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Step forward").help("Step forward by the chosen amount (⌘→)")
                .keyboardShortcut(.rightArrow, modifiers: .command)
            Button { playing.toggle() } label: { Image(systemName: playing ? "pause.fill" : "play.fill") }.accessibilityLabel(playing ? "Pause" : "Play")
                .help(playing ? "Stop stepping" : "Keep stepping forward and watch the charts move")
            Text(label).monospacedDigit().lineLimit(1).frame(maxWidth: .infinity, alignment: .center)
                .help("The moment every card is showing, on the birthplace's clock")
            if store.rectifying {
                Button("Apply") { playing = false; store.applyRectify(); store.rectifying = false }.disabled(store.rectify == 0)
                    .help("Write this time into the birth data")
                Button("Discard") { playing = false; store.rectify = 0; store.rectifying = false }
            } else {
                Button("Rectify") { playing = false; store.goBirth(); store.rectifying = true }
                    .help("Step the birth time itself in seconds and minutes and watch every card change")
            }
            Divider().frame(height: 18)
            // kept here, not in the window's toolbar, where the workspace tabs can crowd them out of sight
            Button { store.paletteShown = true } label: { Label("Search", systemImage: "magnifyingglass") }
                .keyboardShortcut("k", modifiers: .command)
                .help("Type to add a card, switch workspace, change a setting, or ask what a word means (⌘K)")
            Button { store.showHelp.toggle() } label: { Image(systemName: store.showHelp ? "questionmark.circle.fill" : "questionmark.circle") }
                .accessibilityLabel(store.showHelp ? "Hide explanations" : "Show explanations")
                .help(store.showHelp ? "Hide the explanations on each card and in the inspector" : "Show an explanation on each card and in the inspector")
        }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .onReceive(tick) { _ in if playing { store.step(seconds: step) } }
        .onChange(of: store.rectifying) { step = store.rectifying ? 60 : 86400 }
    }
}

/// Type to do anything: add a card, go to a workspace, change a setting.
struct Palette: View {
    @EnvironmentObject var store: Store
    @Binding var shown: Bool
    var report: () -> Void
    @State private var query = ""
    @FocusState private var focused: Bool

    private struct Command: Identifiable {
        let id: String
        let title: String
        let keywords: String
        let run: () -> Void
    }

    private var commands: [Command] {
        var list: [Command] = Store.workspaces.map { name in Command(id: "ws-\(name)", title: "Go to \(name)", keywords: "workspace", run: { store.workspace = name }) }
        list += Catalog.all.map { card in Command(id: "add-\(card.id)", title: "Add \(card.title)", keywords: card.keywords + " card", run: { store.addCard(card.id) }) }
        // looking something up: a term opens the glossary on it; a graha, sign or house is picked
        list += Glossary.basics.map { entry in Command(id: "what-\(entry.term)", title: "What is \(entry.term)?", keywords: "glossary explain meaning define", run: { store.workspace = "Guide"; store.glossary = entry.term }) }
        list += ["Su", "Mo", "Ma", "Me", "Ju", "Ve", "Sa", "Ra", "Ke"].map { code in Command(id: "pick-\(code)", title: "Show \(Names.lords[code] ?? code)", keywords: "graha planet pick " + (store.chart?.graha(code)?.name ?? ""), run: { store.pick = .graha(code) }) }
        list += (0..<12).map { sign in Command(id: "pick-sign-\(sign)", title: "Show \(Names.signs[sign]) (\(Names.signsWestern[sign]))", keywords: "sign rasi pick", run: { store.pick = .sign(sign) }) }
        if let chart = store.chart {
            list += (1...12).map { house in Command(id: "pick-house-\(house)", title: "Show the \(Chart.ordinal(house)) house (\(Lore.houseNames[house - 1].lowercased()))", keywords: "house bhava \(house) pick", run: { store.pick = .sign(chart.sign(ofHouse: house)) }) }
        }
        list += ChartStyle.allCases.map { style in Command(id: "style-\(style.rawValue)", title: "\(style.rawValue) charts", keywords: "style chart form", run: { store.style = style }) }
        list += [
            Command(id: "ay-lahiri", title: "Lahiri ayanamsa", keywords: "chitrapaksha", run: { store.ayanamsa = "lahiri" }),
            Command(id: "ay-truecitra", title: "True Chitra ayanamsa", keywords: "citra spica", run: { store.ayanamsa = "truecitra" }),
            Command(id: "node-mean", title: "Mean node", keywords: "rahu ketu", run: { store.node = "mean" }),
            Command(id: "node-true", title: "True node", keywords: "rahu ketu", run: { store.node = "true" }),
            Command(id: "t-now", title: "Go to now", keywords: "time transit today", run: { store.goNow() }),
            Command(id: "t-birth", title: "Go to the birth", keywords: "time natal", run: { store.goBirth() }),
            Command(id: "rectify", title: "Rectify the birth time", keywords: "adjust", run: { store.goBirth(); store.rectifying = true }),
            Command(id: "report", title: "Write the report (PDF)…", keywords: "print export", run: report),
            Command(id: "help", title: store.showHelp ? "Hide explanations" : "Show explanations", keywords: "help tips learn beginner", run: { store.showHelp.toggle() }),
            Command(id: "sample-1", title: "Add a sample chart: New Delhi, 1 January 2000", keywords: "example explore demo", run: { store.addSample("New Delhi 2000", date: "2000-01-01", time: "17:30:00", zone: "Asia/Kolkata", place: "New Delhi, India", latitude: 28.6139, longitude: 77.209) }),
            Command(id: "sample-2", title: "Add a sample chart: London, 21 June 1990", keywords: "example explore demo", run: { store.addSample("London 1990", date: "1990-06-21", time: "06:00:00", zone: "Europe/London", place: "London, United Kingdom", latitude: 51.5074, longitude: -0.1278) }),
            Command(id: "sample-3", title: "Add a sample chart: New York, 5 November 1985", keywords: "example explore demo", run: { store.addSample("New York 1985", date: "1985-11-05", time: "22:15:00", zone: "America/New_York", place: "New York, United States", latitude: 40.7128, longitude: -74.006) }),
            Command(id: "new", title: "New chart", keywords: "birth person add", run: { store.add() }),
            Command(id: "reset", title: "Restore this workspace's standard cards", keywords: "reset layout", run: { store.resetLayout() }),
        ]
        return list
    }

    private var matches: [Command] {
        let words = query.lowercased().split(separator: " ")
        return commands.filter { command in
            let text = (command.title + " " + command.keywords).lowercased()
            return words.allSatisfy { text.contains($0) }
        }
    }

    private func run(_ command: Command) { command.run(); shown = false }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.25).ignoresSafeArea().onTapGesture { shown = false }
            VStack(alignment: .leading, spacing: 0) {
                TextField("Type what you want: d9, kp, north, true chitra, now, report…", text: $query)
                    .textFieldStyle(.plain).font(.title3).padding(12)
                    .focused($focused)
                    .onSubmit { if let first = matches.first { run(first) } }
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(matches.prefix(14).enumerated()), id: \.element.id) { index, command in
                            Button { run(command) } label: {
                                HStack { Text(command.title); Spacer(); if index == 0 { Text("return").font(.caption).foregroundStyle(.secondary) } }
                                    .padding(.horizontal, 12).padding(.vertical, 6).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(index == 0 ? Color.accentColor.opacity(0.15) : .clear)
                        }
                        if matches.isEmpty { Text("Nothing matches. Try a card's name, a varga such as d10, or a setting.").foregroundStyle(.secondary).padding(12) }
                    }
                }
                .frame(maxHeight: 360)
            }
            .frame(width: 520)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .windowBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15)))
            .padding(.top, 60)
        }
        .onAppear { focused = true }
        .onExitCommand { shown = false }
    }
}

struct SettingsView: View {
    @AppStorage("enginePath") private var enginePath = Engine.defaultRoot
    @AppStorage("kernelPath") private var kernelPath = Engine.defaultKernel

    var body: some View {
        Form {
            TextField("form-jyotish folder", text: $enginePath)
            TextField("coherence-kernel folder", text: $kernelPath)
            Text(Engine.payload == nil ? "The engine is Form: the kernel's fkwu runs engine/chart-run.bml from the form-jyotish folder."
                 : "This app carries its own engine; the two folders above are used only when it is run from source.")
                .font(.footnote).foregroundStyle(.secondary)
            Text(Updater.build.map { "Build \($0). Updates come from github.com/\(Updater.repository) and install when the app restarts." } ?? "Run from source: no updates are fetched.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 560)
    }
}
