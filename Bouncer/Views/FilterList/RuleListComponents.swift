//
//  RuleListComponents.swift
//  Bouncer
//
//  The pieces of the rule list: a masthead that states a fact, a lane selector
//  that carries its own numbers, and rules as cards lit by their category.
//

import SwiftUI

// MARK: - Header

/// The masthead: the name of the screen and one factual line under it. The
/// per-lane numbers live in the selector, next to the control that uses them,
/// rather than being repeated here as decoration.
struct RulesHeader: View {
    let total: Int

    /// Rules, not messages. The statistics block below owns the message count,
    /// and having both say the same sentence made the screen look duplicated.
    private var summary: LocalizedStringKey {
        total == 0 ? "HEADER_NO_RULES" : "HEADER_RULE_SUMMARY \(total)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("LIST_VIEW_TITLE")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Stage.label)
                .accessibilityAddTraits(.isHeader)

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(Stage.secondary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.smooth(duration: 0.3), value: total)
    }
}

// MARK: - Lane selector

/// Three lanes through the door. The selection slides between them and takes on
/// that lane's colour, so the screen tells you where you are before you read a
/// word. Each lane carries its own count — the one number worth glancing at.
struct ScopeSelector: View {
    @Binding var selection: RuleScope
    var counts: (RuleScope) -> Int

    @Namespace private var lane

    var body: some View {
        HStack(spacing: 2) {
            ForEach(RuleScope.allCases) { scope in
                laneButton(scope)
            }
        }
        .padding(3)
        .background(Stage.well, in: .capsule)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("SCOPE_PICKER_LABEL"))
    }

    private func laneButton(_ scope: RuleScope) -> some View {
        let isSelected = selection == scope
        let count = counts(scope)
        return Button {
            withAnimation(.snappy(duration: 0.3, extraBounce: 0.1)) {
                selection = scope
            }
        } label: {
            Text(scope.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(isSelected ? scope.tint : Stage.secondary)
                .frame(maxWidth: .infinity)
            // 11pt + subheadline clears a 44pt target.
            .padding(.vertical, 11)
            .background {
                if isSelected {
                    // One shape, one fill. The tinted type carries the state;
                    // a stroke on top of a stroke on top of a fill was fussy.
                    Capsule()
                        .fill(Stage.fill(scope.tint))
                        .matchedGeometryEffect(id: "lane", in: lane)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(scope.title))
        .accessibilityValue(Text("RULE_COUNT \(count)"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Rule card

/// A rule as a card. The category is the light source — but only where that
/// tells you something. Inside the Junk and Safe lanes every rule shares one
/// destination, so the card drops the badge and the icon well and spends the
/// width on the rule itself; in Categories, where the destination varies, it
/// comes back.
struct RuleCard: View {
    let filter: Filter
    /// True in the Categories lane, where destination differs row to row.
    var showsCategory: Bool = false
    /// What this rule has caught. Absent in previews and the import sheet.
    var activity: RuleActivity? = nil
    /// Import rows and the empty-state example aren't navigable, so they don't
    /// get a disclosure mark.
    var showsChevron: Bool = true
    /// Shared chart scale for the lane this card is in.
    var peak: Int = 1

    private var category: Category { filter.category }

    private var detail: [LocalizedStringKey] {
        var parts: [LocalizedStringKey] = [filter.type.shortTitle]
        if filter.useRegex { parts.append("MODIFIER_REGEX") }
        if filter.caseSensitive { parts.append("MODIFIER_CASE_SENSITIVE") }
        return parts
    }

    var body: some View {
        HStack(spacing: Metrics.m) {
            if showsCategory {
                iconWell
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(filter.displayPhrase)
                    .font(filter.useRegex
                          ? .system(.callout, design: .monospaced).weight(.semibold)
                          : .body.weight(.semibold))
                    .foregroundStyle(Stage.label)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Destination first when it varies, then how the rule matches.
                // Keeping it on this line leaves the trailing column free for
                // the one thing that changes row to row: what it has caught.
                HStack(spacing: 5) {
                    if showsCategory {
                        Text(category.title)
                            .foregroundStyle(category.tint)
                        Circle().frame(width: 2.5, height: 2.5)
                    }
                    ForEach(Array(detail.enumerated()), id: \.offset) { index, part in
                        if index > 0 {
                            Circle().frame(width: 2.5, height: 2.5)
                        }
                        Text(part)
                    }
                }
                .font(.caption)
                .foregroundStyle(Stage.tertiary)
                .lineLimit(1)
            }

            Spacer(minLength: Metrics.s)

            if let activity {
                CatchReadout(activity: activity, tint: category.tint, peak: peak)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Stage.quaternary)
            }
        }
        .padding(.vertical, 16)
        .padding(.leading, Metrics.m + (showsCategory ? 0 : 2))
        .padding(.trailing, Metrics.l - 2)
        .stageCard()
        // The spine only earns its place where the destination differs row to
        // row. In Junk and Safe every rule shares one destination, so a spine
        // there just restated the lane four different ways.
        .overlay(alignment: .leading) {
            if showsCategory {
                Capsule()
                    .fill(category.tint)
                    .frame(width: 3)
                    .padding(.vertical, 16)
                    .padding(.leading, 1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var iconWell: some View {
        Image(systemName: category.symbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(category.tint)
            .frame(width: 34, height: 34)
            .background(Circle().fill(Stage.fill(category.tint, weight: 0.8)))
            .accessibilityHidden(true)
    }
}

/// What a rule has caught in the reporting window, with the same window drawn
/// underneath as a sparkline. One time frame everywhere — the header, the row
/// number and the chart all describe the last 30 days, so the figures on screen
/// can be added up and still agree.
struct CatchReadout: View {
    let activity: RuleActivity
    let tint: Color
    /// The busiest bucket anywhere in this lane. Every row is drawn to the same
    /// scale, so a taller bar always means more messages — normalising each row
    /// to its own peak made a rule with 96 matches out draw one with 179.
    let peak: Int

    private var today: Int { RuleActivityStore.dayIndex() }
    private var count: Int { activity.recentTotal(endingOn: today) }
    private var history: [Int] { activity.history(endingOn: today) }

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            if count == 0 {
                Text("CATCH_NONE")
                    .font(.caption)
                    .foregroundStyle(Stage.tertiary)
                // One continuous line rather than a row of nubs, which read as
                // a dotted rule and made the silhouette look broken.
                Capsule()
                    .fill(Stage.fill(tint))
                    .frame(width: 80, height: 2)
            } else {
                Text(count, format: .number)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                Sparkline(values: history, tint: tint, bucketSize: 3, peak: peak)
                    .frame(width: 80, height: 20)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement()
        .accessibilityLabel(count == 0 ? Text("CATCH_NONE") : Text("CATCH_TOTAL \(count)"))
    }
}

/// A bar chart small enough to live in a row. Thirty daily values in 74pt gave
/// 2.5pt slivers that read as noise, so days are paired into 15 buckets with
/// bars wide enough to see. Empty buckets keep a minimum tick in the same hue,
/// so the baseline is a continuous rhythm rather than a grey dotted line.
struct Sparkline: View {
    let values: [Int]
    let tint: Color
    var bucketSize: Int = 2
    /// Scale to a shared maximum when several charts are meant to be compared.
    var peak: Int? = nil
    /// How strongly empty buckets are drawn. The bigger the chart, the more the
    /// baseline needs to be visible for the gaps to read as data.
    var emptyOpacity: Double = 0.18
    var minimumBarHeight: CGFloat = 2.5

    private var buckets: [Int] {
        stride(from: 0, to: values.count, by: bucketSize).map { start in
            values[start..<min(start + bucketSize, values.count)].reduce(0, +)
        }
    }

    var body: some View {
        let data = buckets
        let scale = max(peak ?? data.max() ?? 1, 1)
        GeometryReader { proxy in
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, value in
                    // Gamma the ratio so small but non zero days clear the
                    // minimum bar height instead of flattening into it.
                    let ratio = pow(CGFloat(value) / CGFloat(scale), 0.6)
                    // A small fixed radius rather than a capsule: at chart
                    // height a fully rounded bar turns into a lozenge and stops
                    // reading as a measurement.
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(value == 0 ? tint.opacity(emptyOpacity) : tint)
                        .frame(maxWidth: 12)
                        .frame(height: max(minimumBarHeight, proxy.size.height * ratio))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

/// The lane's activity, drawn straight on the stage rather than in a card.
///
/// When the summary was a card it was the same object as the rules underneath
/// it — same fill, same radius, same stroke — so the screen read as one
/// undifferentiated stack. Statistics are context, not an item in the list, so
/// they get no container at all: a headline figure, a wide chart, and a rule
/// beneath to close the region. The cards below are then unmistakably the list.
struct LaneSummary: View {
    let scope: RuleScope
    let history: [Int]
    /// Rules in this lane that haven't matched anything in the window. Naming
    /// them is the one thing on this screen the user couldn't work out for
    /// themselves — and the only thing here that suggests an action.
    let idleRules: [Filter]

    private var total: Int { history.reduce(0, +) }

    /// The Categories lane has no colour of its own, and a white chart on a
    /// dark card read as disabled next to rows full of hue.
    private var chartTint: Color {
        scope == .categories ? Brand.tint : scope.tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.m) {
            VStack(alignment: .leading, spacing: 0) {
                Text(total, format: .number)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(chartTint)
                    .contentTransition(.numericText())
                Text("LANE_WINDOW_CAPTION")
                    .font(.footnote)
                    .foregroundStyle(Stage.secondary)
            }

            Sparkline(values: history, tint: chartTint, bucketSize: 1,
                      emptyOpacity: 0.28, minimumBarHeight: 3)
                .frame(height: total == 0 ? 3 : 52)

            if !idleRules.isEmpty, total > 0 {
                Label {
                    Text(idleRules.count == 1
                         ? "LANE_IDLE_ONE \(idleRules[0].displayPhrase)"
                         : "LANE_IDLE_MANY \(idleRules.count)")
                } icon: {
                    Image(systemName: "exclamationmark.circle")
                }
                .font(.footnote)
                .foregroundStyle(Stage.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.smooth(duration: 0.3), value: total)
    }
}

/// Closes the statistics region and opens the list. A plain label over a
/// hairline: the cheapest possible way to say "different kind of thing below".
struct RuleListHeader: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            Rectangle()
                .fill(Stage.cardStroke)
                .frame(height: 0.5)
            Text("RULE_SECTION_HEADER \(count)")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundStyle(Stage.tertiary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Empty state

/// What an empty lane shows: ghosts of the cards that will live here, then the
/// explanation. Showing the shape of the thing you're about to make beats an
/// illustration — it teaches the row layout before the first rule exists.
struct EmptyStage: View {
    let scope: RuleScope
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: Metrics.l) {
            Text(scope.emptyTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Stage.label)
                .multilineTextAlignment(.center)

            Text(scope.emptyMessage)
                .font(.subheadline)
                .foregroundStyle(Stage.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onAdd) {
                Text(scope.addRuleTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(scope.tint)
                    .padding(.horizontal, Metrics.xl)
                    .padding(.vertical, Metrics.m)
                    .background(Stage.fill(scope.tint), in: .capsule)
            }
            .buttonStyle(.plain)
            .padding(.top, Metrics.xs)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Nothing matched the search.
struct NoResultsStage: View {
    let query: String

    var body: some View {
        VStack(spacing: Metrics.s) {
            Text("NO_RESULTS \(query)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Stage.label)
                .multilineTextAlignment(.center)
            Text("NO_RESULTS_DETAIL")
                .font(.subheadline)
                .foregroundStyle(Stage.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Metrics.xxl)
    }
}

#Preview {
    ZStack {
        BackgroundView()
        ScrollView {
            VStack(spacing: Metrics.l) {
                RulesHeader(total: 21)
                ScopeSelector(selection: .constant(.junk), counts: { _ in 3 })
                RuleCard(filter: Filter(id: UUID(), phrase: "free bitcoin",
                                        type: .sender, action: .junk))
                RuleCard(filter: Filter(id: UUID(), phrase: "^WIN.*$", type: .message,
                                        action: .promotion, subAction: .promotionOffers,
                                        useRegex: true, caseSensitive: true),
                         showsCategory: true)
                EmptyStage(scope: .allow, onAdd: {})
            }
            .padding(Metrics.l)
        }
    }
}
