import SwiftUI

/// Vimshottari as a timeline: rows for mahadasha, antardasha and finer levels as the span narrows.
/// Dragging along it moves the moment under view; a click also picks the period under the pointer.
struct DashaTimeline: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    /// years shown
    @State private var span = 120.0
    /// Julian day at the left edge
    @State private var start = 0.0

    private static let spans: [(name: String, years: Double)] = [("120 y", 120), ("30 y", 30), ("6 y", 6), ("1 y", 1), ("6 w", 0.115)]
    private static let levelNames = ["Mahadasha", "Antardasha", "Pratyantardasha", "Sookshma"]
    private let rowHeight: CGFloat = 24

    private var days: Double { span * 365.25 }
    private var last: Double { chart.dasha.last?.end ?? chart.jd + 120 * 365.25 }
    private var levels: Int { span > 30 ? 2 : span > 6 ? 3 : 4 }

    private func recentre() {
        let centre = store.viewDay ?? chart.jd
        start = min(max(chart.jd, centre - days / 2), max(chart.jd, last - days))
    }

    /// the periods of each level that reach into the window, each with its lords from the mahadasha down
    private var rows: [[(lords: [String], period: Period)]] {
        let inside = { (p: Period) in p.end > start && p.start < start + days }
        var result: [[(lords: [String], period: Period)]] = [chart.dasha.filter(inside).map { ([$0.lord], $0) }]
        for _ in 1..<levels {
            result.append(result[result.count - 1].flatMap { parent in Vimshottari.parts(of: parent.period).filter(inside).map { (parent.lords + [$0.lord], $0) } })
        }
        return result
    }

    var body: some View {
        let rows = rows
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Picker("Span", selection: $span) { ForEach(Self.spans, id: \.years) { Text($0.name).tag($0.years) } }
                    .pickerStyle(.segmented).labelsHidden().frame(width: 280)
                    .help("How much time the timeline shows; narrower spans show finer periods")
                Text("Drag to move through time; click a period to pick it.").font(.footnote).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                let width = geo.size.width
                Canvas { context, _ in
                    for (level, row) in rows.enumerated() {
                        let y = CGFloat(level) * rowHeight
                        for entry in row {
                            let x0 = max(0, (entry.period.start - start) / days * width), x1 = min(width, (entry.period.end - start) / days * width)
                            let rect = CGRect(x: x0, y: y + 1, width: max(0.5, x1 - x0), height: rowHeight - 2)
                            let picked = store.pick == .period(lords: entry.lords, start: entry.period.start, end: entry.period.end)
                            context.fill(Path(rect), with: .color(Tint.graha(entry.period.lord).opacity(picked ? 0.6 : 0.28)))
                            context.stroke(Path(rect), with: .color(picked ? .accentColor : .primary.opacity(0.25)), lineWidth: picked ? 2 : 0.5)
                            if rect.width > 24 {
                                let name = rect.width > 70 ? (Names.lords[entry.period.lord] ?? entry.period.lord) : entry.period.lord
                                context.draw(Text(name).font(.system(size: 11)), at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
                            }
                        }
                    }
                    if let day = store.viewDay, day >= start, day <= start + days {
                        let x = (day - start) / days * width
                        var line = Path(); line.move(to: CGPoint(x: x, y: 0)); line.addLine(to: CGPoint(x: x, y: CGFloat(rows.count) * rowHeight))
                        context.stroke(line, with: .color(.accentColor), lineWidth: 2)
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in store.go(to: min(max(chart.jd, start + Double(value.location.x / width) * days), last - 0.001)) }
                    .onEnded { value in
                        guard abs(value.translation.width) < 3 else { return }
                        let level = Int(value.location.y / rowHeight), day = start + Double(value.location.x / width) * days
                        if rows.indices.contains(level), let hit = rows[level].first(where: { $0.period.holds(day) }) {
                            store.pick = .period(lords: hit.lords, start: hit.period.start, end: hit.period.end)
                        }
                    })
                .accessibilityLabel("Vimshottari timeline")
            }
            .frame(height: CGFloat(rows.count) * rowHeight)
            HStack {
                Text(Names.date(julianDay: start).formatted(date: .abbreviated, time: .omitted))
                Spacer()
                Text(Self.levelNames.prefix(rows.count).joined(separator: " · "))
                Spacer()
                Text(Names.date(julianDay: start + days).formatted(date: .abbreviated, time: .omitted))
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .onAppear { recentre() }
        .onChanged(of: span) { recentre() }
        .onChanged(of: chart.jd) { recentre() }
        .onChanged(of: store.viewDay) { if let day = store.viewDay, day < start || day > start + days { recentre() } }
    }
}

/// One Vimshottari period that opens into its nine parts, down to the sookshma dasha.
struct DashaNode: View {
    @EnvironmentObject var store: Store
    let period: Period
    let lords: [String]
    let birth: Double
    @State private var open = false

    private var name: String { lords.map { lords.count == 1 ? (Names.lords[$0] ?? $0) : (Names.lordsThree[$0] ?? $0) }.joined(separator: "–") }
    private var pick: Pick { .period(lords: lords, start: period.start, end: period.end) }

    var body: some View {
        let format = Date.FormatStyle(date: .abbreviated, time: lords.count > 2 ? .shortened : .omitted, timeZone: store.zone)
        let running = store.viewDay.map(period.holds) ?? false
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                if lords.count < 4 {
                    Button { open.toggle() } label: { Image(systemName: open ? "chevron.down" : "chevron.right").frame(width: 12) }
                        .buttonStyle(.plain).accessibilityLabel(open ? "Collapse \(name)" : "Expand \(name)")
                } else {
                    Color.clear.frame(width: 12, height: 1)
                }
                Text(name).foregroundStyle(Tint.graha(period.lord)).frame(width: 190, alignment: .leading)
                Text("\(Names.date(julianDay: max(period.start, birth)).formatted(format)) – \(Names.date(julianDay: period.end).formatted(format))").foregroundStyle(.secondary)
            }
            .fontWeight(running ? .bold : .regular)
            .padding(.vertical, 1).padding(.horizontal, 4)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.accentColor.opacity(store.pick == pick ? 0.25 : 0)))
            .contentShape(Rectangle())
            .onTapGesture { store.pick = pick }
            if open {
                ForEach(Vimshottari.parts(of: period).filter { $0.end > birth }) { part in
                    DashaNode(period: part, lords: lords + [part.lord], birth: birth).padding(.leading, 18)
                }
            }
        }
    }
}

struct DashaList: View {
    let chart: Chart
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(chart.dasha.filter { $0.end > chart.jd }) { maha in
                DashaNode(period: maha, lords: [maha.lord], birth: chart.jd)
            }
        }
        .monospacedDigit()
    }
}
