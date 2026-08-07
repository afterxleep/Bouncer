//
//  OnboardingIllustrations.swift
//  Bouncer
//
//  The setup steps happen in the Settings app, so each step shows a miniature
//  of the screen the user is looking at with the row they need picked out.
//  Drawn rather than screenshotted: it stays sharp at any size, translates with
//  the rest of the UI, and never goes stale when iOS restyles Settings.
//

import SwiftUI

// MARK: - Building blocks

private enum Mock {
    static let rowHeight: CGFloat = 34
    static let iconSize: CGFloat = 22
    static let corner: CGFloat = 12
    static let inset: CGFloat = 12

    static let surface = Color.white.opacity(0.10)
    static let surfaceRaised = Color.white.opacity(0.16)
    static let label = Color.white.opacity(0.92)
    static let secondary = Color.white.opacity(0.45)
    static let separator = Color.white.opacity(0.10)
}

/// A rounded app-icon tile, the way Settings draws them next to a row.
private struct MockIcon: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = Mock.iconSize

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(tint.gradient)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }
}

/// One row of a Settings list. `highlighted` is the row the step is asking the
/// user to tap.
private struct MockRow: View {
    var symbol: String? = nil
    var tint: Color = .gray
    let title: LocalizedStringKey
    var accessory: Accessory = .chevron
    var highlighted = false

    enum Accessory {
        case chevron
        case toggle(Bool)
        case checkmark
        case none
    }

    var body: some View {
        HStack(spacing: 9) {
            if let symbol {
                MockIcon(symbol: symbol, tint: tint)
            }
            Text(title)
                .font(.system(size: 11, weight: highlighted ? .semibold : .regular))
                .foregroundStyle(highlighted ? Mock.label : Mock.label.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Spacer(minLength: 4)
            accessoryView
        }
        .padding(.horizontal, 10)
        .frame(height: Mock.rowHeight)
        .background {
            if highlighted {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.55), lineWidth: 1.5)
                    }
                    .padding(.horizontal, 3)
            }
        }
    }

    @ViewBuilder private var accessoryView: some View {
        switch accessory {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Mock.secondary)
        case .toggle(let isOn):
            Capsule()
                .fill(isOn ? Color(red: 0.30, green: 0.85, blue: 0.39) : Color.white.opacity(0.25))
                .frame(width: 26, height: 16)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 13, height: 13)
                        .padding(1.5)
                }
        case .checkmark:
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        case .none:
            EmptyView()
        }
    }
}

/// The miniature Settings window the rows sit in.
private struct MockScreen<Content: View>: View {
    let title: LocalizedStringKey
    var showsBack = true
    var footer: LocalizedStringKey? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                if showsBack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Mock.label)
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Mock.label)
                Spacer()
            }
            .padding(.horizontal, Mock.inset)
            .padding(.top, 20)
            .padding(.bottom, 10)

            VStack(spacing: 0) { content }
                .background(Mock.surface, in: .rect(cornerRadius: Mock.corner, style: .continuous))
                .padding(.horizontal, Mock.inset)

            if let footer {
                Text(footer)
                    .font(.system(size: 9))
                    .foregroundStyle(Mock.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Mock.inset + 6)
                    .padding(.top, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
    }
}

/// A hairline between mock rows, inset past the icon like the real thing.
private struct MockDivider: View {
    var inset: CGFloat = 41
    var body: some View {
        Rectangle()
            .fill(Mock.separator)
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}

// MARK: - Steps

/// Step 1 — find Settings on the Home Screen.
private struct OpenSettingsIllustration: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            MockIcon(symbol: "gearshape.fill", tint: Color(white: 0.55), size: 74)
                .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
                .overlay {
                    RoundedRectangle(cornerRadius: 74 * 0.26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: 2)
                        .padding(-6)
                }
            Text("ONBOARDING_MOCK_SETTINGS")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Mock.label)
            Spacer(minLength: 0)
        }
    }
}

/// Step 2 — Settings ▸ Apps.
private struct AppsListIllustration: View {
    var body: some View {
        MockScreen(title: "ONBOARDING_MOCK_SETTINGS", showsBack: false) {
            MockRow(symbol: "gearshape.fill", tint: Color(white: 0.5), title: "ONBOARDING_MOCK_GENERAL")
            MockDivider()
            MockRow(symbol: "figure.wave", tint: .blue, title: "ONBOARDING_MOCK_ACCESSIBILITY")
            MockDivider()
            MockRow(symbol: "hand.raised.fill", tint: Color(white: 0.45), title: "ONBOARDING_MOCK_PRIVACY")
            MockDivider()
            MockRow(symbol: "icloud.fill", tint: Color(red: 0.35, green: 0.68, blue: 0.95), title: "ONBOARDING_MOCK_ICLOUD")
            MockDivider()
            MockRow(symbol: "square.grid.2x2.fill", tint: Color(red: 0.35, green: 0.45, blue: 0.95),
                    title: "ONBOARDING_MOCK_APPS", highlighted: true)
        }
    }
}

/// Step 3 — Apps ▸ Messages.
private struct MessagesRowIllustration: View {
    var body: some View {
        MockScreen(title: "ONBOARDING_MOCK_APPS") {
            MockRow(symbol: "calendar", tint: .red, title: "ONBOARDING_MOCK_CALENDAR")
            MockDivider()
            MockRow(symbol: "person.crop.square.fill", tint: Color(white: 0.5), title: "ONBOARDING_MOCK_CONTACTS")
            MockDivider()
            MockRow(symbol: "map.fill", tint: .green, title: "ONBOARDING_MOCK_MAPS")
            MockDivider()
            MockRow(symbol: "message.fill", tint: Color(red: 0.30, green: 0.85, blue: 0.39),
                    title: "ONBOARDING_MOCK_MESSAGES", highlighted: true)
            MockDivider()
            MockRow(symbol: "safari.fill", tint: Color(red: 0.25, green: 0.55, blue: 0.95),
                    title: "ONBOARDING_MOCK_SAFARI")
        }
    }
}

/// Step 4 — Messages ▸ Text Message Filtering.
private struct MessageFilterIllustration: View {
    var body: some View {
        MockScreen(title: "ONBOARDING_MOCK_MESSAGES",
                   footer: "ONBOARDING_MOCK_UNKNOWN_FOOTER") {
            MockRow(title: "ONBOARDING_MOCK_IMESSAGE", accessory: .toggle(true))
            MockDivider(inset: 10)
            MockRow(title: "ONBOARDING_MOCK_READ_RECEIPTS", accessory: .toggle(false))
            MockDivider(inset: 10)
            MockRow(title: "ONBOARDING_MOCK_SCREEN_UNKNOWN", accessory: .toggle(true))
            MockDivider(inset: 10)
            MockRow(title: "ONBOARDING_MOCK_FILTERING", highlighted: true)
        }
    }
}

/// Step 5 — pick Bouncer as the filter.
private struct EnableBouncerIllustration: View {
    var body: some View {
        MockScreen(title: "ONBOARDING_MOCK_FILTERING",
                   footer: "ONBOARDING_MOCK_FILTERING_FOOTER") {
            MockRow(title: "ONBOARDING_MOCK_OFF", accessory: .none)
            MockDivider(inset: 10)
            MockRow(symbol: "shield.lefthalf.filled", tint: OnboardingStyle.accent,
                    title: "ONBOARDING_MOCK_BOUNCER", accessory: .checkmark, highlighted: true)
        }
    }
}

// MARK: - Entry point

/// The illustration for a step, or nothing for the welcome page.
struct OnboardingIllustration: View {
    let page: OnboardingPage

    var body: some View {
        switch page {
        case .welcome: EmptyView()
        case .step1: OpenSettingsIllustration()
        case .step2: AppsListIllustration()
        case .step3: MessagesRowIllustration()
        case .step4: MessageFilterIllustration()
        case .step5: EnableBouncerIllustration()
        }
    }
}

#Preview {
    ZStack {
        OnboardingBackdrop()
        ScrollView {
            VStack(spacing: 24) {
                ForEach([OnboardingPage.step1, .step2, .step3, .step4, .step5]) { page in
                    DeviceFrameView(page: page).frame(height: 380)
                }
            }
            .padding(28)
        }
    }
}
