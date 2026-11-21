import SwiftUI

/// The desks, as tabs above the workspace.
///
/// The tabs have stopped answering clicks more than once, each time because of what they stood inside: the
/// window's toolbar, a strip that scrolled sideways (a click that moved a hair was taken for a drag), the
/// zoomed area. So they are built to depend on none of it:
///   - they stand outside the zoomed area and outside any scroll view, and wrap onto a second line when the
///     window is narrow, so every tab is always on screen;
///   - each tab is one plain button whose whole pill is its label, with nothing laid over it;
///   - the Desk menu and ⌘1 to ⌘9 reach the same desks without a click;
///   - `FormJyotish --probe-tabs` clicks every tab with real mouse events, and `make-app.sh` runs it, so a
///     build whose tabs do not answer does not get made.
struct WorkspaceTabs: View {
    @EnvironmentObject var store: Store
    /// where each tab stands in the window, top-left origin: read by the tab probe
    static var spots: [String: CGRect] = [:]

    var body: some View {
        let scale = store.textScale
        HStack(alignment: .top, spacing: 8) {
            Flow(spacing: 4 * scale) {
                ForEach(Store.workspaces.filter { !Store.additions.contains($0) }, id: \.self) { tab($0, scale: scale) }
                Toggle(isOn: $store.showAdditions) { Text("Additions · not in Light on Life").font(.system(size: 11 * scale, weight: .semibold)) }
                    .toggleStyle(.checkbox).tint(Catalog.additionTint).foregroundStyle(Catalog.additionTint)
                    .padding(.horizontal, 8 * scale)
                    .help("Desks and cards whose methods Light on Life does not teach: Jaimini, KP, the annual chart, matching, shadbala, ashtakavarga and the other dasha systems. Untick to hide them all and keep to the textbook.")
                if store.showAdditions {
                    ForEach(Store.workspaces.filter(Store.additions.contains), id: \.self) { tab($0, scale: scale) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button { store.inspectorShown.toggle() } label: {
                Image(systemName: "sidebar.right").font(.system(size: 14 * scale)).padding(5 * scale).contentShape(Rectangle())
            }
            .buttonStyle(.plain).foregroundStyle(store.inspectorShown ? Color.accentColor : Color.secondary)
            .accessibilityLabel(store.inspectorShown ? "Hide the explanation column" : "Show the explanation column")
            .help(store.inspectorShown ? "Hide the explanation column at the right (⌥⌘I)" : "Show the explanation column at the right (⌥⌘I)")
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
    }

    private func tab(_ name: String, scale: Double) -> some View {
        let chosen = store.workspace == name, addition = Store.additions.contains(name)
        return Button { store.workspace = name } label: {
            Text(name)
                .font(.system(size: 13 * scale, weight: chosen ? .semibold : .regular))
                .foregroundStyle(addition ? Catalog.additionTint : chosen ? Color.primary : Color.secondary)
                .padding(.horizontal, 12 * scale).padding(.vertical, 5 * scale)
                .background(Capsule().fill(Color.accentColor.opacity(chosen ? 0.22 : 0)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(Help.workspace(name))
        .background(GeometryReader { geo in
            let place = geo.frame(in: .global)
            Color.clear.onAppear { WorkspaceTabs.spots[name] = place }.onChanged(of: place) { WorkspaceTabs.spots[name] = geo.frame(in: .global) }
        })
    }
}

/// Lays its views in a line and starts a new line when the next one does not fit.
struct Flow: Layout {
    var spacing: CGFloat = 4

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = [], x: CGFloat = 0, y: CGFloat = 0, line: CGFloat = 0, widest: CGFloat = 0, start = 0
        func centre(_ end: Int) { for i in start..<end { frames[i].origin.y = y + (line - frames[i].height) / 2 } }
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width { centre(frames.count); start = frames.count; x = 0; y += line + spacing; line = 0 }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            x += size.width + spacing; line = max(line, size.height); widest = max(widest, x - spacing)
        }
        centre(frames.count)
        return (CGSize(width: widest, height: y + line), frames)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews, width: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (view, frame) in zip(subviews, arrange(subviews, width: bounds.width).frames) {
            view.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }
}

/// The edge between the workspace and the explanation column: drag it to make the column wider or narrower;
/// dragged nearly shut, the column closes.
struct InspectorHandle: View {
    @EnvironmentObject var store: Store
    @State private var from: Double?
    @State private var over = false

    var body: some View {
        Rectangle().fill(Color.primary.opacity(over || from != nil ? 0.25 : 0.1)).frame(width: 1)
            .padding(.horizontal, 3).frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onHover { inside in
                if inside != over { over = inside; if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() } }
            }
            .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { drag in
                    let start = from ?? store.inspectorWidth
                    if from == nil { from = start }
                    // the window measures the drag; the column is measured in the zoomed area's own units
                    store.inspectorWidth = min(Store.inspectorWidest, max(60, start - drag.translation.width / store.textScale))
                }
                .onEnded { _ in
                    from = nil
                    if store.inspectorWidth < Store.inspectorNarrowest - 30 { store.inspectorShown = false; store.inspectorWidth = Store.inspectorStandard }
                    else { store.inspectorWidth = max(Store.inspectorNarrowest, store.inspectorWidth) }
                })
            .help("Drag to make the explanation column wider or narrower; drag it nearly shut to hide it")
    }
}
