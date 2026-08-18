//
//  ImportFilterListView.swift
//  Bouncer
//

import SwiftUI

/// Review step for an imported file: pick which rules to keep before they're
/// written to the store.
struct ImportFilterListView: View {
    var existingFilters: [Filter]
    var filters: [Filter]
    let onAdd: ([Filter]) -> Void
    let onCancel: () -> Void

    private let newFilters: [Filter]
    private let duplicateFilters: [Filter]

    @State private var selectedFilters: Set<Filter> = []

    init(existingFilters: [Filter],
         filters: [Filter],
         onAdd: @escaping ([Filter]) -> Void,
         onCancel: @escaping () -> Void) {
        self.existingFilters = existingFilters
        self.filters = filters
        self.newFilters = filters.filter { !existingFilters.contains($0) }
        self.duplicateFilters = filters.filter { existingFilters.contains($0) }
        self.onAdd = onAdd
        self.onCancel = onCancel
        self._selectedFilters = .init(initialValue: Set(self.newFilters))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()
                list
            }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .navigationTitle("IMPORT_TITLE")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("CANCEL", role: .cancel) { onCancel() }
                    }
                    ToolbarItem(placement: .topBarTrailing) { selectionMenu }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            onAdd(Array(selectedFilters))
                        } label: {
                            // "Add 0" reads like a broken string; drop the
                            // count entirely when nothing is selected.
                            if selectedFilters.isEmpty {
                                Text("IMPORT_CONFIRM_EMPTY")
                            } else {
                                Text("IMPORT_CONFIRM \(selectedFilters.count)")
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(selectedFilters.isEmpty)
                        .accessibilityIdentifier("import.confirm")
                    }
                }
        }
        .tint(Brand.tint)
    }
}

// MARK: - Content

private extension ImportFilterListView {

    @ViewBuilder var list: some View {
        if filters.isEmpty {
            VStack(spacing: Metrics.s) {
                Text("EMPTY_IMPORT_FILE")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Stage.label)
                Text("EMPTY_IMPORT_FILE_DETAIL")
                    .font(.subheadline)
                    .foregroundStyle(Stage.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(Metrics.xl)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Metrics.xl) {
                    if !newFilters.isEmpty {
                        group("NEW_FILTERS", footer: "NEW_FILTERS_FOOTER", items: newFilters)
                    }
                    if !duplicateFilters.isEmpty {
                        group("DUPLICATE_FILTERS", footer: "DUPLICATE_FILTERS_FOOTER", items: duplicateFilters)
                    }
                }
                .padding(.horizontal, Metrics.l)
                .padding(.vertical, Metrics.m)
            }
            .scrollIndicators(.hidden)
            .animation(.smooth(duration: 0.2), value: selectedFilters)
        }
    }

    func group(_ title: LocalizedStringKey,
               footer: LocalizedStringKey,
               items: [Filter]) -> some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Stage.secondary)
                .padding(.leading, Metrics.xs)
            VStack(spacing: Metrics.s) {
                ForEach(items) { row($0) }
            }
            Text(footer)
                .font(.caption)
                .foregroundStyle(Stage.tertiary)
                .padding(.leading, Metrics.xs)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func row(_ filter: Filter) -> some View {
        let isSelected = selectedFilters.contains(filter)
        return Button {
            toggle(filter)
        } label: {
            HStack(spacing: Metrics.m) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Brand.tint : Stage.quaternary)
                    .contentTransition(.symbolEffect(.replace))
                RuleCard(filter: filter, showsCategory: true, showsChevron: false)
                    .opacity(isSelected ? 1 : 0.55)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    var selectionMenu: some View {
        Menu {
            Button("SELECT_ALL", systemImage: "checklist.checked") {
                selectedFilters = Set(filters)
            }
            Button("SELECT_NEW", systemImage: "checklist") {
                selectedFilters = Set(newFilters)
            }
            Button("SELECT_NONE", systemImage: "checklist.unchecked") {
                selectedFilters = []
            }
        } label: {
            Label("SELECTION_OPTIONS", systemImage: "checklist")
        }
    }

    func toggle(_ filter: Filter) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
    }
}

#Preview {
    ImportFilterListView(
        existingFilters: [Filter(id: UUID(), phrase: "casino", action: .junk)],
        filters: [
            Filter(id: UUID(), phrase: "lottery", type: .sender, action: .junk),
            Filter(id: UUID(), phrase: "casino", action: .junk),
        ],
        onAdd: { _ in },
        onCancel: {})
}
