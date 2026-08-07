//
//  OnboardingView.swift
//  Bouncer
//

import SwiftUI

struct OnboardingView: View {
    enum Mode { case firstRun, help }

    let mode: Mode
    let canSendMail: Bool
    let onOpenSettings: () -> Void
    let onFinish: () -> Void

    @State private var selection: OnboardingPage
    @State private var isShowingContactView = false
    @State private var isShowingMailAlert = false

    init(mode: Mode,
         canSendMail: Bool,
         onOpenSettings: @escaping () -> Void,
         onFinish: @escaping () -> Void) {
        self.mode = mode
        self.canSendMail = canSendMail
        self.onOpenSettings = onOpenSettings
        self.onFinish = onFinish
        _selection = State(initialValue: mode == .help ? .step1 : .welcome)
    }

    private var pages: [OnboardingPage] {
        mode == .help
            ? OnboardingPage.allCases.filter { $0 != .welcome }
            : OnboardingPage.allCases
    }

    private var selectedIndex: Int {
        pages.firstIndex(of: selection) ?? 0
    }

    private func advance(to page: OnboardingPage) {
        withAnimation(.smooth(duration: 0.35)) {
            selection = page
        }
    }

    // MARK: - Pager

    private var pager: some View {
        TabView(selection: $selection) {
            ForEach(pages) { page in
                Group {
                    if page == .welcome {
                        OnboardingWelcomePage(isActive: selection == .welcome)
                    } else {
                        OnboardingStepPage(page: page)
                    }
                }
                .tag(page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.smooth(duration: 0.35), value: selection)
    }

    // MARK: - Top bar

    /// Back and close/skip sit on one baseline, inset from the top by the same
    /// amount as from the side. They used to be different heights — one an
    /// icon, one a label — and hard against the sheet's edge.
    private static let barControl: CGFloat = 32

    private var topBar: some View {
        HStack(alignment: .center, spacing: 0) {
            if selection != pages.first, let previous = OnboardingPage(rawValue: selection.rawValue - 1) {
                Button {
                    advance(to: previous)
                } label: {
                    Image(systemName: "chevron.backward")
                        .frame(width: Self.barControl, height: Self.barControl)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OnboardingStyle.textSecondary)
                .accessibilityIdentifier("onboarding.back")
            }

            Spacer(minLength: 0)

            // First run can be skipped; opened from Help it needs a way out on
            // every page, not just the last one.
            if mode == .help {
                Button("ONBOARDING_CLOSE", systemImage: "xmark") {
                    onFinish()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OnboardingStyle.textSecondary)
                .frame(width: Self.barControl, height: Self.barControl)
                .contentShape(.rect)
                .accessibilityIdentifier("onboarding.close")
            } else if selection == .welcome {
                Button("ONBOARDING_SKIP") {
                    onFinish()
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OnboardingStyle.textSecondary)
                .frame(height: Self.barControl)
                .contentShape(.rect)
                .accessibilityIdentifier("onboarding.skip")
            }
        }
        .frame(height: Self.barControl)
        .padding(.horizontal, OnboardingStyle.pageHorizontalPadding)
        // Matches the side inset, so the corner reads as square.
        .padding(.top, OnboardingStyle.pageHorizontalPadding)
        .padding(.bottom, Metrics.s)
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private var ctaRow: some View {
        switch selection {
        case .welcome:
            primaryButton("ONBOARDING_GET_STARTED") { advance(to: .step1) }
        case .step1:
            HStack(spacing: 12) {
                primaryButton("ONBOARDING_OPEN_SETTINGS") { onOpenSettings() }
                secondaryButton("ONBOARDING_NEXT") { advance(to: .step2) }
            }
        case .step2:
            primaryButton("ONBOARDING_NEXT") { advance(to: .step3) }
        case .step3:
            primaryButton("ONBOARDING_NEXT") { advance(to: .step4) }
        case .step4:
            primaryButton("ONBOARDING_NEXT") { advance(to: .step5) }
        case .step5:
            primaryButton("ONBOARDING_DONE") { onFinish() }
        }
    }

    private static let ctaHeight: CGFloat = 52

    private func primaryButton(_ titleKey: LocalizedStringKey,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(titleKey)
                .font(.body.weight(.semibold))
                // The tint lightens for dark mode, so the legible pairing
                // flips with it.
                .foregroundStyle(Stage.onTint)
                .frame(maxWidth: .infinity)
                .frame(height: Self.ctaHeight)
                .background(Capsule().fill(Brand.tint))
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.cta.primary")
    }

    private func secondaryButton(_ titleKey: LocalizedStringKey,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(titleKey)
                .font(.body.weight(.semibold))
                .foregroundStyle(Stage.label)
                .frame(maxWidth: .infinity)
                .frame(height: Self.ctaHeight)
                .background(Capsule().fill(OnboardingStyle.surfaceFill))
                .overlay(Capsule().strokeBorder(Stage.cardStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.cta.secondary")
    }

    private var supportLink: some View {
        Button("NEED_HELP") {
            if canSendMail {
                isShowingContactView = true
            } else {
                isShowingMailAlert = true
            }
        }
        .buttonStyle(.plain)
        .font(.footnote)
        .foregroundStyle(OnboardingStyle.textSecondary)
        .accessibilityIdentifier("onboarding.help")
    }

    private var bottomBar: some View {
        VStack(spacing: 18) {
            OnboardingPageDots(count: pages.count, index: selectedIndex)
            ctaRow
            // First run only, and only once past the welcome page. Opened from
            // Help the user already has a support button one screen back.
            if mode == .firstRun, selection != .welcome {
                supportLink
            }
        }
        .padding(.horizontal, OnboardingStyle.pageHorizontalPadding)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            OnboardingBackdrop()
            VStack(spacing: 0) {
                topBar
                pager
                bottomBar
            }
        }
        .sheet(isPresented: $isShowingContactView) {
            ContactView(result: $isShowingContactView)
        }
        .alert("ASK_ANYTHING", isPresented: $isShowingMailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("NO_EMAIL_CONFIGURED")
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(mode: .firstRun,
                       canSendMail: false,
                       onOpenSettings: {},
                       onFinish: {})
    }
}
