//
//  FilterDetailView.swift
//  Bouncer
//

import SwiftUI

/// The rule editor, used both as a sheet (new rule) and pushed (edit).
///
/// Built around the phrase, because the phrase is the rule. Everything else is
/// two short answers — where to look, where it goes — answered by tapping, and
/// the whole thing is summed up in one plain sentence so you can read what
/// you've built without decoding three controls.
struct FilterDetailView<L: View, R: View>: View {

    var isEmbedded = true
    var title: LocalizedStringKey
    var leadingBarItem: L
    var trailingBarItem: R

    @Binding var filterType: FilterType
    @Binding var filterDestination: FilterDestination
    @Binding var filterTerm: String
    @Binding var exactMatch: Bool
    @Binding var useRegex: Bool
    @Binding var isCaseSensitive: Bool

    @FocusState private var termIsFocused: Bool
    @State private var scrolled = false
    @State private var showingCategoryPicker = false
    // Starts collapsed and only opens itself if the rule being edited
    // already uses it — a new rule shouldn't have to see it.
    @State private var showingAdvanced = false

    private var accent: Color { filterDestination.category.tint }

    var body: some View {
        if isEmbedded {
            NavigationStack {
                stage
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { leadingBarItem }
                        ToolbarItem(placement: .confirmationAction) { trailingBarItem }
                    }
            }
            .presentationDetents([.large])
            .onAppear { termIsFocused = filterTerm.isEmpty }
        } else {
            stage
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { trailingBarItem }
                }
        }
    }

    private var stage: some View {
        ZStack {
            BackgroundView()
            form
        }
        // Transparent at rest so the sheet reads as one surface; a hairline
        // appears once content is under the bar, so nothing slides beneath the
        // title unannounced.
        .safeAreaInset(edge: .top, spacing: 0) {
            Rectangle()
                .fill(Stage.cardStroke)
                .frame(height: 0.5)
                .opacity(scrolled ? 1 : 0)
                .animation(.easeOut(duration: 0.15), value: scrolled)
        }
        .toolbarBackgroundVisibility(scrolled ? .visible : .hidden, for: .navigationBar)
    }
}

// MARK: - Form

private extension FilterDetailView {

    var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.xl) {
                section("FILTER_CONTAINS_TEXT_LABEL") { phraseField }
                summarySentence
                lookInSection
                sendToSection
                advancedSection
            }
            .padding(.horizontal, Metrics.l)
            .padding(.top, Metrics.m)
            .padding(.bottom, Metrics.xxl)
            .onScrollVisibilityChange { _ in }
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > 4
        } action: { _, isScrolled in
            scrolled = isScrolled
        }
        .scrollDismissesKeyboard(.interactively)
        .animation(.smooth(duration: 0.25), value: filterDestination)
        .animation(.smooth(duration: 0.25), value: filterType)
        .animation(.smooth(duration: 0.25), value: useRegex)
        .onAppear {
            showingAdvanced = useRegex || isCaseSensitive
        }
        .sheet(isPresented: $showingCategoryPicker) {
            categoryPicker
        }
    }

    /// The phrase is the rule, so it gets the weight: a tall well, 20pt text,
    /// and a border in the destination colour while you're typing.
    var phraseField: some View {
        TextField("FILTER_TEXT_PLACEHOLDER", text: $filterTerm, axis: .vertical)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .lineLimit(1...3)
            .focused($termIsFocused)
            .font(useRegex ? .system(.title3, design: .monospaced) : .title3)
            .foregroundStyle(Stage.label)
            .tint(accent)
            .padding(.horizontal, Metrics.l)
            .padding(.vertical, Metrics.m)
            .frame(minHeight: 56)
            // Deliberately brighter than a plain card: this is the one field on
            // the sheet and it should read as the place to type.
            .background(Stage.adaptive(light: .white, dark: Color.white.opacity(0.10)),
                        in: .rect(cornerRadius: Metrics.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .strokeBorder(termIsFocused ? accent.opacity(0.55) : Stage.cardStroke,
                                  lineWidth: termIsFocused ? 1.5 : 1)
            }
            .animation(.easeOut(duration: 0.15), value: termIsFocused)
            .accessibilityIdentifier("rule.phrase")
    }

    /// The rule, read back as a sentence. Built from one format string rather
    /// than concatenated fragments so translators control the word order, then
    /// the three substituted values are emphasised by finding them in the
    /// result — which keeps the emphasis wherever the sentence puts them.
    var summarySentence: some View {
        Text(summaryText)
            .font(.subheadline)
            .foregroundStyle(Stage.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Metrics.xs)
            .accessibilityIdentifier("rule.summary")
    }

    var summaryText: AttributedString {
        let scope = filterType.sentenceFragment
        let phrase = filterTerm.isBlank
            ? String(localized: "RULE_SENTENCE_ANY_PHRASE")
            : "“\(filterTerm.trimmed)”"
        let destination = filterDestination.category.name

        var text = AttributedString(
            String(format: String(localized: "RULE_SENTENCE %1$@ %2$@ %3$@"),
                   scope, phrase, destination))

        for (value, colour) in [(scope, Stage.label),
                                (phrase, Stage.label),
                                (destination, accent)] {
            if let range = text.range(of: value) {
                text[range].foregroundColor = colour
                text[range].font = .subheadline.weight(.semibold)
            }
        }
        return text
    }

    /// Same control as the destinations below it. Two different affordances for
    /// the same kind of question — a checkmark list here, chips there — made one
    /// short form feel like two.
    var lookInSection: some View {
        section("FILTER_SCOPE_SECTION") {
            chipGrid(minimum: 150) {
                ForEach(FilterType.allCases, id: \.self) { value in
                    // Short labels here; the sentence above spells out the
                    // full meaning, so the chip only has to be identifiable.
                    chip(title: value.shortTitle,
                         symbol: value.symbol,
                         tint: accent,
                         isSelected: filterType == value) {
                        filterType = value
                    }
                }
            }
            .accessibilityIdentifier("rule.scope")
        }
    }

    /// Three buttons, one decision: kept, blocked, or sorted. The first two
    /// cover almost every rule anyone writes, so they're right here. The
    /// third doesn't have a destination of its own — it pops the other ten
    /// as a sheet, and once one's picked, becomes that category: its own
    /// icon, name and colour, same as Safe and Junk.
    var sendToSection: some View {
        section("FILTER_ACTION_SECTION") {
            HStack(spacing: Metrics.s) {
                destinationTile(.allow)
                destinationTile(.junk)
                categoryTile
            }
            .accessibilityIdentifier("rule.destination")
        }
    }

    func destinationTile(_ destination: FilterDestination) -> some View {
        tile(symbol: destination.category.symbol,
             title: destination.category.title,
             tint: destination.category.tint,
             isSelected: filterDestination == destination) {
            filterDestination = destination
        }
        .accessibilityIdentifier("rule.destination.\(destination.rawValue)")
    }

    var categoryTile: some View {
        let isSelected = filterDestination.isCategory
        let category = isSelected ? filterDestination.category : Category(
            symbol: "square.grid.2x2.fill", tint: Brand.tint,
            titleKey: "SCOPE_CATEGORIES", shortKey: "SCOPE_CATEGORIES")
        return tile(symbol: category.symbol, title: category.title, tint: category.tint, isSelected: isSelected) {
            showingCategoryPicker = true
        }
        .accessibilityIdentifier("rule.category.tile")
    }

    func tile(symbol: String, title: LocalizedStringKey, tint: Color,
             isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? tint : Stage.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(isSelected ? Stage.fill(tint) : Stage.card,
                        in: .rect(cornerRadius: Metrics.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .strokeBorder(isSelected ? Stage.edge(tint) : Stage.cardStroke,
                                  lineWidth: isSelected ? 1.5 : 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// Picking a destination here dismisses the sheet immediately — there's
    /// nothing else to decide once you've named the category.
    var categoryPicker: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.xl) {
                    destinationGroup("TRANSACTIONS", [.transactionOrder, .transactionFinance,
                                                      .transactionReminders, .transactionHealth,
                                                      .transactionOther])
                    destinationGroup("PROMOTIONS", [.promotionOffers, .promotionCoupons, .promotionOther])
                }
                .padding(Metrics.l)
            }
            .background { BackgroundView() }
            .navigationTitle(Text("SCOPE_CATEGORIES"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("DONE") { showingCategoryPicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    func destinationGroup(_ title: LocalizedStringKey, _ options: [FilterDestination]) -> some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Stage.tertiary)
                .padding(.leading, Metrics.xs)
            chipGrid(minimum: 150) {
                ForEach(options, id: \.self) { option in
                    let category = option.category
                    chip(title: category.title,
                         symbol: category.symbol,
                         tint: category.tint,
                         isSelected: filterDestination == option) {
                        filterDestination = option
                        showingCategoryPicker = false
                    }
                }
            }
        }
    }

    func chipGrid<Content: View>(minimum: CGFloat,
                                 @ViewBuilder content: () -> Content) -> some View {
        // Two columns at 150pt: four-item groups fall 2×2 instead of orphaning
        // one chip on its own row, and full category names fit without eliding.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum), spacing: Metrics.s)],
                  alignment: .leading, spacing: Metrics.s, content: content)
    }

    func chip(title: LocalizedStringKey,
              symbol: String,
              tint: Color,
              isSelected: Bool,
              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? tint : Stage.secondary)
            .padding(.horizontal, Metrics.m)
            .padding(.vertical, 6)
            .frame(minHeight: 46)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Stage.fill(tint) : Stage.card,
                        in: .rect(cornerRadius: Metrics.badgeRadius + 2, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.badgeRadius + 2, style: .continuous)
                    .strokeBorder(isSelected ? Stage.edge(tint) : Stage.cardStroke, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// Regex and case-sensitivity are for the rules that need precision, not
    /// the rule you're writing right now — collapsed unless the one you're
    /// editing already turned one of them on.
    var advancedSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.smooth(duration: 0.22)) { showingAdvanced.toggle() }
            } label: {
                HStack(spacing: Metrics.s) {
                    Text("ADVANCED")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Stage.label)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Stage.quaternary)
                        .rotationEffect(.degrees(showingAdvanced ? 90 : 0))
                }
                .padding(.horizontal, Metrics.l)
                .frame(height: 52)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("rule.advanced.toggle")

            if showingAdvanced {
                divider
                optionToggle($useRegex,
                             title: "USE_REGULAR_EXPRESSIONS",
                             detail: "USE_REGULAR_EXPRESSIONS_DETAIL")
                divider
                regexPrimerLink
                divider
                optionToggle($isCaseSensitive,
                             title: "IS_CASE_SENSITIVE",
                             detail: "IS_CASE_SENSITIVE_DETAIL")
            }
        }
        .stageCard()
        .accessibilityIdentifier("rule.advanced")
    }

    /// Regular expressions are the one thing in this form that can't be
    /// explained in a sentence, so point at somewhere that teaches them from
    /// nothing rather than trying. Sits next to the switch it belongs to, and
    /// shows whether or not the switch is on, so it can be read before
    /// committing to the option.
    @ViewBuilder var regexPrimerLink: some View {
        if let url = URL(string: "https://regexone.com") {
            Link(destination: url) {
                HStack(spacing: Metrics.m) {
                    Image(systemName: "book")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                        .frame(width: 20)
                    Text("REGEX_LEARN_MORE")
                        .font(.subheadline)
                        .foregroundStyle(accent)
                    Spacer(minLength: Metrics.s)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Stage.quaternary)
                }
                .padding(.horizontal, Metrics.l)
                .padding(.vertical, Metrics.m)
                .contentShape(.rect)
            }
            .accessibilityIdentifier("rule.regexHelp")
        }
    }

    // MARK: Pieces

    func section<Content: View>(_ title: LocalizedStringKey,
                                @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Stage.secondary)
                .padding(.leading, Metrics.xs)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func optionToggle(_ binding: Binding<Bool>,
                      title: LocalizedStringKey,
                      detail: LocalizedStringKey) -> some View {
        Toggle(isOn: binding) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Stage.label)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Stage.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(accent)
        .padding(.horizontal, Metrics.l)
        .padding(.vertical, Metrics.m)
    }

    var divider: some View {
        Rectangle()
            .fill(Stage.cardStroke)
            .frame(height: 0.5)
            .padding(.leading, Metrics.l)
    }
}

// MARK: - Sentence fragments

extension FilterType {
    /// The clause this scope contributes to the plain-language summary.
    var sentenceFragment: String {
        switch self {
        case .any: return String(localized: "RULE_SENTENCE_SCOPE_ANY")
        case .sender: return String(localized: "RULE_SENTENCE_SCOPE_SENDER")
        case .message: return String(localized: "RULE_SENTENCE_SCOPE_MESSAGE")
        }
    }
}

#Preview {
    FilterDetailView(title: "NEW_FILTER",
                     leadingBarItem: Button("CANCEL") {},
                     trailingBarItem: Button("SAVE") {},
                     filterType: .constant(.sender),
                     filterDestination: .constant(.promotionOffers),
                     filterTerm: .constant("casino"),
                     exactMatch: .constant(false),
                     useRegex: .constant(false),
                     isCaseSensitive: .constant(false))
}
