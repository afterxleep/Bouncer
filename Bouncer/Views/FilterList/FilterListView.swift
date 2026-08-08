//
//  FilterListView.swift
//  Bouncer
//

import SwiftUI
import UniformTypeIdentifiers

/// The three lanes through the door. Kept separate from `FilterDestination` so
/// the selector stays a UI concern.
enum RuleScope: String, CaseIterable, Identifiable {
    case junk, allow, categories

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .allow: return "SCOPE_SAFE"
        case .junk: return "SCOPE_JUNK"
        case .categories: return "SCOPE_CATEGORIES"
        }
    }

    var symbol: String {
        switch self {
        case .allow: return "checkmark.shield.fill"
        case .junk: return "hand.raised.fill"
        case .categories: return "square.grid.2x2.fill"
        }
    }

    var tint: Color {
        switch self {
        case .allow: return Brand.safe
        case .junk: return Brand.junk
        // The brand tint rather than a category hue: this lane holds every
        // colour, so borrowing one made the same amber mean "this lane" and
        // "Offers" on a single screen.
        case .categories: return Brand.tint
        }
    }

    /// The destination a rule added from this lane should default to.
    var defaultDestination: FilterDestination {
        switch self {
        case .allow: return .allow
        case .junk: return .junk
        case .categories: return .promotionOther
        }
    }

    var emptyTitle: LocalizedStringKey {
        switch self {
        case .allow: return "EMPTY_LIST_ALLOW_TITLE"
        case .junk: return "EMPTY_LIST_JUNK_TITLE"
        case .categories: return "EMPTY_LIST_OTHER_TITLE"
        }
    }

    /// The empty-state button says what it will make, so it doesn't read as a
    /// duplicate of the toolbar's "+".
    var addRuleTitle: LocalizedStringKey {
        switch self {
        case .allow: return "ADD_RULE_SAFE"
        case .junk: return "ADD_RULE_JUNK"
        case .categories: return "ADD_RULE_CATEGORY"
        }
    }

    var emptyMessage: LocalizedStringKey {
        switch self {
        case .allow: return "EMPTY_LIST_ALLOW_MESSAGE"
        case .junk: return "EMPTY_LIST_JUNK_MESSAGE"
        case .categories: return "EMPTY_LIST_OTHER_MESSAGE"
        }
    }

    func contains(_ filter: Filter) -> Bool {
        switch self {
        case .allow: return filter.action == .allow
        case .junk: return filter.action == .junk
        case .categories: return filter.action != .allow && filter.action != .junk
        }
    }
}

struct FilterListView: View {
    var filters: [Filter]
    let onDelete: (UUID) -> Void
    let onImport: ([Filter]) -> Void
    let importFiltersFromURL: (URL) -> Void
    let openSettings: () -> Void
    let showError: (FilterError) -> Void
    @Binding var shouldShowImportList: Bool

    @State private var showingHelp = false
    @State private var showingFilterDetail = false
    @State private var showingFileImporter = false
    @State private var searchText = ""
    @State private var scope: RuleScope = .junk
    @State private var deleteCount = 0
    @State private var scrolled = false
    @State private var atBottom = false
    @State private var editingFilter: Filter?
    /// What each rule has caught, read from the shared container the filter
    /// extension writes to. Refreshed whenever the app comes forward, since the
    /// extension runs while we're in the background.
    @State private var activity = RuleActivityLog()
    @Environment(\.scenePhase) private var scenePhase

    private var scopedFilters: [Filter] {
        filters.filter { scope.contains($0) }
    }

    /// What the list actually shows, busiest first. Sorting by matches puts the
    /// rules doing the work at the top and lets the dead ones sink, which is the
    /// order you want the moment a list grows past a screenful. Ties fall back
    /// to alphabetical so the order is stable.
    private var visibleFilters: [Filter] {
        let matching = searchText.isEmpty
            ? scopedFilters
            : scopedFilters.filter { $0.phrase.localizedCaseInsensitiveContains(searchText) }
        let today = RuleActivityStore.dayIndex()
        return matching.sorted { first, second in
            let a = activity.rules[first.id.uuidString]?.recentTotal(endingOn: today) ?? 0
            let b = activity.rules[second.id.uuidString]?.recentTotal(endingOn: today) ?? 0
            if a != b { return a > b }
            return first.phrase.localizedCaseInsensitiveCompare(second.phrase) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()
                content
            }
            // The screen draws its own masthead, so there is nothing in the
            // navigation bar to carry a scroll-edge material. Cover the status
            // bar band instead, fading in once content travels under it —
            // without this the lane selector slid behind the clock.
            .safeAreaInset(edge: .top, spacing: 0) {
                // A zero-height inset whose background is explicitly allowed to
                // bleed upward, which fills exactly the status bar band.
                Color.clear
                    .frame(height: 0)
                    .background(.ultraThinMaterial, ignoresSafeAreaEdges: .top)
                    .opacity(scrolled ? 1 : 0)
                    .animation(.easeOut(duration: 0.18), value: scrolled)
                    .allowsHitTesting(false)
            }
            // The system's own edge effect rather than a painted gradient: a
            // solid fade to the stage colour drew a visible band, because the
            // background gradient hasn't reached that colour by the time the
            // fade starts.
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $editingFilter) { filter in
                FilterDetailContainerView(interactionType: .update, filter: filter)
            }
            .toolbar {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItemGroup(placement: .bottomBar) {
                    libraryMenu
                    addButton
                }
            }
        }
        .searchable(text: $searchText, prompt: Text("SEARCH_RULES"))
        // Rule phrases are lower-case far more often than not; the keyboard
        // shifting on every query was fighting the user.
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .task { refreshActivity() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshActivity() }
        }
        .sensoryFeedback(.selection, trigger: scope)
        .sensoryFeedback(.impact(weight: .light), trigger: deleteCount)
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                importFiltersFromURL(url)
            case .failure(let error):
                showError(.unknownError(error.localizedDescription))
            }
        }
        .sheet(isPresented: $shouldShowImportList) {
            ImportFilterListContainerView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingFilterDetail) {
            FilterDetailContainerView(selectedDestination: scope.defaultDestination)
        }
    }
}

// MARK: - Content

private extension FilterListView {

    func count(_ scope: RuleScope) -> Int {
        filters.filter { scope.contains($0) }.count
    }

    /// The lane's own last 30 days, summed across its rules — the answer to
    /// "is this thing actually doing anything?".
    var laneHistory: [Int] {
        let today = RuleActivityStore.dayIndex()
        // Always a full window, even with no data at all — an empty array left
        // the chart as a blank gap instead of a flat baseline.
        var totals = [Int](repeating: 0, count: RuleActivity.historyLength)
        for filter in scopedFilters {
            guard let history = activity.rules[filter.id.uuidString]?.history(endingOn: today) else { continue }
            for (day, value) in history.enumerated() where day < totals.count {
                totals[day] += value
            }
        }
        return totals
    }

    /// The busiest three-day bucket belonging to any single rule in this lane.
    /// Every row chart is drawn to this scale, so bar height is comparable
    /// between rows. It must come from individual rules, not from the lane
    /// total — scaling to the sum flattened every row to a fifth of its height.
    var lanePeak: Int {
        let today = RuleActivityStore.dayIndex()
        let peaks = scopedFilters.map { filter -> Int in
            guard let history = activity.rules[filter.id.uuidString]?.history(endingOn: today) else { return 0 }
            let buckets = stride(from: 0, to: history.count, by: 3).map { start in
                history[start..<min(start + 3, history.count)].reduce(0, +)
            }
            return buckets.max() ?? 0
        }
        return max(peaks.max() ?? 1, 1)
    }

    /// Rules that haven't matched anything in the window.
    var idleRules: [Filter] {
        let today = RuleActivityStore.dayIndex()
        return scopedFilters.filter { (activity.rules[$0.id.uuidString]?.recentTotal(endingOn: today) ?? 0) == 0 }
    }

    func refreshActivity() {
        activity = RuleActivityStore.shared.load()
        // Never prune against an empty list. The filter reducer leaves
        // `filters` empty when the store fails to load, and pruning on the
        // strength of a failed read would delete every rule's history.
        guard !filters.isEmpty else { return }
        RuleActivityStore.shared.prune(keeping: Set(filters.map(\.id)))
    }

    /// A `List` rather than a scrolling stack: swipe-to-delete is the gesture
    /// people reach for on a row, and it is worth using the system's rather than
    /// approximating it with a drag. Every chrome affordance is switched off so
    /// the cards still sit on the stage.
    var content: some View {
        // Everything derived from `filters` × `activity` is worked out once
        // here and handed down. Read as computed properties they were
        // re-evaluated several times per body, and `lanePeak` in particular ran
        // once per row — walking the whole lane each time.
        let rows = visibleFilters
        let peak = lanePeak
        let history = laneHistory
        let idle = idleRules

        return List {
            Group {
                header

                ScopeSelector(selection: $scope, counts: count)
                    .padding(.horizontal, Metrics.l)
                    .padding(.bottom, Metrics.m)

                if rows.isEmpty {
                    emptyState
                        .padding(.horizontal, Metrics.l)
                        .padding(.top, Metrics.xl)
                } else {
                    // Above the rules, not below them: at the foot of a long
                    // list the lane's summary is unreachable exactly when it
                    // matters most. It only appears once there is something to
                    // report — a big "0" over a flat line is pure noise on a
                    // lane that simply hasn't caught anything yet.
                    if searchText.isEmpty, history.contains(where: { $0 > 0 }) {
                        LaneSummary(scope: scope, history: history, idleRules: idle)
                            .padding(.horizontal, Metrics.l)
                            .padding(.bottom, Metrics.xl)
                    }
                    RuleListHeader(count: rows.count)
                        .padding(.horizontal, Metrics.l)
                        .padding(.bottom, Metrics.m)
                }
            }
            .modifier(BareRow())

            ForEach(rows) { filter in
                ruleRow(filter, peak: peak)
                    .modifier(BareRow())
                    .padding(.horizontal, Metrics.l)
                    .padding(.bottom, 10)
            }

            Color.clear
                .frame(height: 120)
                .modifier(BareRow())
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > 8
        } action: { _, isScrolled in
            scrolled = isScrolled
        }
        .animation(.smooth(duration: 0.3), value: rows)
        .animation(.snappy(duration: 0.3), value: scope)
    }

    /// Masthead. This is a tool people open to do one job, so the header states
    /// the facts and gets out of the way — no decoration above the fold.
    var header: some View {
        RulesHeader(total: filters.count)
            .padding(.horizontal, Metrics.l)
            .padding(.top, 0)
            .padding(.bottom, Metrics.l)
    }

    /// A button driving `navigationDestination` rather than a `NavigationLink`:
    /// inside a `List` the link draws its own disclosure accessory outside the
    /// card, so every row had two chevrons.
    func ruleRow(_ filter: Filter, peak: Int) -> some View {
        Button {
            editingFilter = filter
        } label: {
            RuleCard(filter: filter,
                     showsCategory: scope == .categories,
                     activity: activity[filter.id],
                     peak: peak)
        }
        .buttonStyle(.plain)
        // Destructive stays red whatever lane it is in: a green "Delete" in the
        // Safe lane would be actively misleading.
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("DELETE", systemImage: "trash", role: .destructive) {
                delete(filter)
            }
            .tint(.red)
        }
        .contextMenu {
            Button("DELETE", systemImage: "trash", role: .destructive) {
                delete(filter)
            }
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.94).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)))
    }

    @ViewBuilder var emptyState: some View {
        if !searchText.isEmpty {
            NoResultsStage(query: searchText)
        } else {
            EmptyStage(scope: scope) { showingFilterDetail = true }
        }
    }
}

// MARK: - Toolbar

private extension FilterListView {

    var addButton: some View {
        Button("ADD_RULE", systemImage: "plus") {
            showingFilterDetail = true
        }
        // Always the brand tint: coloured by lane, the "+" turned red in Junk,
        // and a red plus reads as destructive.
        .tint(Brand.tint)
    }

    var libraryMenu: some View {
        Menu {
            Button("IMPORT_BLOCK_LIST", systemImage: "square.and.arrow.down") {
                showingFileImporter = true
            }
            if let fileURL = FilterStoreFile.fileURL {
                ShareLink(item: fileURL) {
                    Label("EXPORT_BLOCK_LIST", systemImage: "square.and.arrow.up")
                }
            }
            Divider()
            Button("HELP", systemImage: "questionmark.circle") {
                showingHelp = true
            }
        } label: {
            Label("MORE_ACTIONS", systemImage: "ellipsis")
        }
        .tint(Stage.label)
    }

    func delete(_ filter: Filter) {
        deleteCount += 1
        withAnimation(.smooth(duration: 0.3)) {
            onDelete(filter.id)
        }
    }
}

/// Removes every default list decoration so a row is just the card.
private struct BareRow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

#Preview {
    FilterListView(filters: [
        Filter(id: UUID(), phrase: "free bitcoin", type: .sender, action: .junk),
        Filter(id: UUID(), phrase: "you have won", action: .junk),
    ],
                   onDelete: { _ in },
                   onImport: { _ in },
                   importFiltersFromURL: { _ in },
                   openSettings: {},
                   showError: { _ in },
                   shouldShowImportList: .constant(false))
}
