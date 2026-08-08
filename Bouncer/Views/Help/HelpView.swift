//
//  HelpView.swift
//  Bouncer
//
//  The place to go when filtering isn't working. Two things belong here and
//  nothing else: how to finish the setup iOS requires, and how to reach a
//  person. Previously "Help" replayed the setup walkthrough with no way out of
//  it and no way to ask a question.
//

import SwiftUI
import MessageUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingWalkthrough = false
    @State private var isShowingContact = false
    @State private var isShowingMailAlert = false

    private var canSendMail: Bool { MFMailComposeViewController.canSendMail() }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()
                content
            }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("DONE") { dismiss() }
                        .tint(Stage.secondary)
                        .accessibilityIdentifier("help.done")
                }
            }
        }
        .tint(Brand.tint)
        .sheet(isPresented: $isShowingWalkthrough) {
            OnboardingContainerView(mode: .help)
        }
        .sheet(isPresented: $isShowingContact) {
            ContactView(result: $isShowingContact)
        }
        .alert("ASK_ANYTHING", isPresented: $isShowingMailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("NO_EMAIL_CONFIGURED")
        }
    }
}

// MARK: - Content

private extension HelpView {

    var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.xl) {
                intro
                setupSection
                supportSection
                privacyNote
                versionFooter
            }
            .padding(.horizontal, Metrics.l)
            .padding(.top, Metrics.s)
            .padding(.bottom, Metrics.xxl)
        }
        .scrollIndicators(.hidden)
    }

    var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HELP_TITLE")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Stage.label)
                .accessibilityAddTraits(.isHeader)
            Text("HELP_INTRO")
                .font(.subheadline)
                .foregroundStyle(Stage.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Setup

    /// iOS will not let an app turn its own message filter on, so the only
    /// honest thing to do is show exactly where the switch lives.
    var setupSection: some View {
        section("HELP_SETUP_SECTION", footer: "HELP_SETUP_FOOTER") {
            VStack(spacing: Metrics.m) {
                VStack(spacing: 0) {
                    ForEach(Array(SetupStep.allCases.enumerated()), id: \.element) { index, step in
                        if index > 0 { divider }
                        stepRow(number: index + 1, title: step.title)
                    }
                }
                .stageCard()

                VStack(spacing: 0) {
                    actionRow(title: "HELP_OPEN_SETTINGS",
                              symbol: "arrow.up.forward.app",
                              tint: Brand.tint) {
                        SystemSettings.open()
                    }
                    divider
                    actionRow(title: "HELP_SHOW_WALKTHROUGH",
                              symbol: "list.number",
                              tint: Brand.tint) {
                        isShowingWalkthrough = true
                    }
                }
                .stageCard()
            }
        }
    }

    func stepRow(number: Int, title: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.m) {
            Text(number, format: .number)
                .font(.footnote.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Brand.tint)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Brand.tint.opacity(0.16)))
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Stage.label)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Metrics.l)
        .padding(.vertical, Metrics.m)
        .accessibilityElement(children: .combine)
    }

    // MARK: Support

    var supportSection: some View {
        section("HELP_SUPPORT_SECTION", footer: "HELP_SUPPORT_FOOTER") {
            VStack(spacing: 0) {
                actionRow(title: "HELP_EMAIL_SUPPORT",
                          symbol: "envelope.fill",
                          tint: Brand.safe) {
                    // Without a mail account the compose sheet appears and does
                    // nothing, so offer the address instead.
                    if canSendMail {
                        isShowingContact = true
                    } else {
                        isShowingMailAlert = true
                    }
                }
            }
            .stageCard()
        }
    }

    var privacyNote: some View {
        HStack(alignment: .top, spacing: Metrics.m) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.safe)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text("HELP_PRIVACY")
                .font(.footnote)
                .foregroundStyle(Stage.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Metrics.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .stageCard()
        .accessibilityElement(children: .combine)
    }

    var versionFooter: some View {
        Text("HELP_VERSION \(Bundle.main.displayVersion)")
            .font(.caption)
            .foregroundStyle(Stage.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .textSelection(.enabled)
    }

    // MARK: Pieces

    func section<Content: View>(_ title: LocalizedStringKey,
                                footer: LocalizedStringKey? = nil,
                                @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Stage.secondary)
                .padding(.leading, Metrics.xs)
            content()
            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(Stage.tertiary)
                    .padding(.leading, Metrics.xs)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func actionRow(title: LocalizedStringKey,
                   symbol: String,
                   tint: Color,
                   action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Metrics.m) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 22)
                Text(title)
                    .font(.body)
                    .foregroundStyle(Stage.label)
                Spacer(minLength: Metrics.s)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Stage.quaternary)
            }
            .padding(.horizontal, Metrics.l)
            .frame(height: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    var divider: some View {
        Rectangle()
            .fill(Stage.cardStroke)
            .frame(height: 0.5)
            .padding(.leading, Metrics.l + 22 + Metrics.m)
    }
}

// MARK: - Steps

/// The setup iOS requires, in the order Settings presents it. Kept in one place
/// so the help list and the walkthrough can never describe different steps.
private enum SetupStep: CaseIterable {
    case openSettings, apps, messages, filter, enable

    var title: LocalizedStringKey {
        switch self {
        case .openSettings: return "ONBOARDING_STEP_1_TITLE"
        case .apps: return "ONBOARDING_STEP_2_TITLE"
        case .messages: return "ONBOARDING_STEP_3_TITLE"
        case .filter: return "ONBOARDING_STEP_4_TITLE"
        case .enable: return "ONBOARDING_STEP_5_TITLE"
        }
    }
}

#Preview {
    HelpView()
}
