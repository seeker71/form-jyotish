import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: Store
    @AppStorage("enginePath") private var enginePath = Engine.defaultRoot
    @AppStorage("kernelPath") private var kernelPath = Engine.defaultKernel
    @AppStorage("node") private var node = "mean"
    @AppStorage("style") private var style = ChartStyle.south.rawValue
    @AppStorage("ayanamsa") private var ayanamsa = "lahiri"

    private var engine: Engine { Engine(root: URL(fileURLWithPath: enginePath), kernel: URL(fileURLWithPath: kernelPath)) }
    private var chartStyle: ChartStyle { ChartStyle(rawValue: style) ?? .south }

    var body: some View {
        NavigationSplitView {
            List(selection: $store.selection) {
                ForEach(store.births) { birth in
                    Text(birth.name.isEmpty ? "Unnamed" : birth.name)
                        .tag(birth.id)
                        .contextMenu { Button("Delete", role: .destructive) { store.remove(birth.id) } }
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 200)
            .toolbar { Button { store.add() } label: { Label("New chart", systemImage: "plus") } }
        } detail: {
            if let index = store.index {
                detail($store.births[index])
            } else {
                ContentUnavailableView("No chart selected", systemImage: "sparkles", description: Text("Add a chart with the + button."))
            }
        }
        .toolbar {
            Picker("Chart style", selection: $style) {
                ForEach(ChartStyle.allCases) { Text($0.rawValue).tag($0.rawValue) }
            }
            Picker("Ayanamsa", selection: $ayanamsa) {
                Text("Lahiri").tag("lahiri")
                Text("True Chitra").tag("truecitra")
            }
            Picker("Node", selection: $node) {
                Text("Mean node").tag("mean")
                Text("True node").tag("true")
            }
        }
        .onChange(of: store.selection) { store.chart = nil; store.calculate(engine: engine, node: node, ayanamsa: ayanamsa) }
        .onChange(of: node) { store.calculate(engine: engine, node: node, ayanamsa: ayanamsa) }
        .onChange(of: ayanamsa) { store.calculate(engine: engine, node: node, ayanamsa: ayanamsa) }
        .onAppear { store.calculate(engine: engine, node: node, ayanamsa: ayanamsa) }
    }

    private func detail(_ birth: Binding<Birth>) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                birthForm(birth)
                if let problem = store.problem {
                    Label(problem, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                }
                if let chart = store.chart, store.chartOf == birth.wrappedValue.id {
                    HStack(alignment: .top, spacing: 20) {
                        ChartDiagram(style: chartStyle, title: "Rasi", ascSign: chart.asc.sign, bySign: labels(chart, navamsa: false))
                        ChartDiagram(style: chartStyle, title: "Navamsa", ascSign: chart.asc.navamsa, bySign: labels(chart, navamsa: true))
                    }
                    .frame(maxHeight: 420)
                    Text("\(Names.ayanamsas[chart.ayanamsa_mode] ?? chart.ayanamsa_mode) ayanamsa \(Names.dms(chart.ayanamsa)) · \(chart.node) node · TT − UTC \(String(format: "%.1f", chart.delta_t)) s")
                        .font(.footnote).foregroundStyle(.secondary)
                    grahaTable(chart)
                    dashaList(chart, zone: birth.wrappedValue.timeZone ?? .current)
                }
            }
            .padding(20)
        }
    }

    private func birthForm(_ birth: Binding<Birth>) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Text("Name")
                TextField("Name", text: birth.name).gridCellColumns(3)
            }
            GridRow {
                Text("Date")
                TextField("YYYY-MM-DD", text: birth.date)
                Text("Time")
                TextField("HH:MM:SS", text: birth.time)
            }
            GridRow {
                Text("Place")
                TextField("City, country", text: birth.place).onSubmit { store.lookUpPlace() }
                Button("Look up") { store.lookUpPlace() }.disabled(birth.wrappedValue.place.isEmpty)
                    .help("Sends the place name to Apple's geocoder and fills latitude, longitude and time zone.")
                TextField("Time zone", text: birth.zone)
                    .foregroundStyle(birth.wrappedValue.timeZone == nil ? .red : .primary)
            }
            GridRow {
                Text("Latitude")
                TextField("north +", value: birth.latitude, format: .number.precision(.fractionLength(0...4)))
                Text("Longitude")
                TextField("east +", value: birth.longitude, format: .number.precision(.fractionLength(0...4)))
            }
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                HStack {
                    Button("Calculate") { store.calculate(engine: engine, node: node, ayanamsa: ayanamsa) }
                        .keyboardShortcut(.return, modifiers: .command)
                        .buttonStyle(.borderedProminent)
                    if store.busy { ProgressView().controlSize(.small) }
                    Button("Report…") { exportReport() }
                        .disabled(store.chart == nil || store.chartOf != store.selection)
                        .help("Writes the chart as a PDF report.")
                }
                .gridCellColumns(3)
            }
        }
        .textFieldStyle(.roundedBorder)
        .labelsHidden()
        .frame(maxWidth: 640)
    }

    private func exportReport() {
        guard let index = store.index, let chart = store.chart else { return }
        let birth = store.births[index]
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(birth.name.isEmpty ? "Chart" : birth.name).pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if Report(birth: birth, chart: chart).write(to: url) { NSWorkspace.shared.open(url) } else { store.problem = "The report could not be written to \(url.path)." }
    }

    private func labels(_ chart: Chart, navamsa: Bool) -> [Int: [String]] {
        var bySign: [Int: [String]] = [(navamsa ? chart.asc.navamsa : chart.asc.sign): ["As"]]
        for graha in chart.grahas {
            let label = navamsa ? graha.id : "\(graha.id)\(graha.retro && graha.id != "Ra" && graha.id != "Ke" ? "℞" : "") \(Int(graha.deg))°"
            bySign[navamsa ? graha.navamsa : graha.sign, default: []].append(label)
        }
        return bySign
    }

    private func grahaTable(_ chart: Chart) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 5) {
            GridRow {
                ForEach(["Graha", "Rasi", "Longitude", "Nakshatra", "Pada", "Lord", "Navamsa", "Motion °/day"], id: \.self) {
                    Text($0).font(.caption).foregroundStyle(.secondary)
                }
            }
            Divider()
            placementRow("Lagna", chart.asc.sign, chart.asc.deg, chart.asc.nak_name, chart.asc.pada, chart.asc.nak_lord, chart.asc.navamsa, motion: "")
            ForEach(chart.grahas) { graha in
                placementRow("\(graha.name) (\(graha.id))", graha.sign, graha.deg, graha.nak_name, graha.pada, graha.nak_lord, graha.navamsa,
                             motion: String(format: "%+.4f", graha.speed) + (graha.retro ? " ℞" : ""))
            }
        }
        .monospacedDigit()
    }

    private func placementRow(_ name: String, _ sign: Int, _ deg: Double, _ nak: String, _ pada: Int, _ lord: String, _ navamsa: Int, motion: String) -> some View {
        GridRow {
            Text(name).fontWeight(.medium)
            Text(Names.signs[sign])
            Text(Names.dms(deg))
            Text(nak)
            Text("\(pada)")
            Text(Names.lords[lord] ?? lord)
            Text(Names.signs[navamsa])
            Text(motion)
        }
    }

    private func dashaList(_ chart: Chart, zone: TimeZone) -> some View {
        let format = Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: zone)
        func span(_ period: Period) -> String {
            "\(Names.date(julianDay: period.start).formatted(format)) – \(Names.date(julianDay: period.end).formatted(format))"
        }
        let now = Date().timeIntervalSince1970 / 86400 + 2440587.5
        return VStack(alignment: .leading, spacing: 6) {
            Text("Vimshottari dasha").font(.headline)
            ForEach(chart.dasha.filter { $0.end > chart.jd }) { maha in
                DisclosureGroup {
                    ForEach((maha.antar ?? []).filter { $0.end > chart.jd }) { antar in
                        HStack {
                            Text("\(Names.lords[maha.lord] ?? maha.lord) – \(Names.lords[antar.lord] ?? antar.lord)").frame(width: 170, alignment: .leading)
                            Text(span(antar)).foregroundStyle(.secondary)
                        }
                        .fontWeight(antar.holds(now) ? .bold : .regular)
                        .padding(.leading, 12)
                    }
                } label: {
                    HStack {
                        Text(Names.lords[maha.lord] ?? maha.lord).frame(width: 170, alignment: .leading)
                        Text(span(maha)).foregroundStyle(.secondary)
                    }
                    .fontWeight(maha.holds(now) ? .bold : .regular)
                }
            }
        }
        .monospacedDigit()
        .frame(maxWidth: 520, alignment: .leading)
    }
}

struct SettingsView: View {
    @AppStorage("enginePath") private var enginePath = Engine.defaultRoot
    @AppStorage("kernelPath") private var kernelPath = Engine.defaultKernel

    var body: some View {
        Form {
            TextField("form-jyotish folder", text: $enginePath)
            TextField("coherence-kernel folder", text: $kernelPath)
            Text("The engine is Form: the kernel's fkwu runs engine/chart-run.bml from the form-jyotish folder.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 560)
    }
}
