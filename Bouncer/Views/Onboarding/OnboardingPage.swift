//
//  OnboardingPage.swift
//  Bouncer
//

import SwiftUI

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome, step1, step2, step3, step4, step5

    var id: Int { rawValue }

    /// 1...5 for step pages, nil for welcome.
    var stepNumber: Int? { rawValue == 0 ? nil : rawValue }

    static var stepCount: Int { allCases.count - 1 }

    var titleKey: LocalizedStringKey {
        switch self {
        case .welcome: return "ONBOARDING_WELCOME_TITLE"
        case .step1: return "ONBOARDING_STEP_1_TITLE"
        case .step2: return "ONBOARDING_STEP_2_TITLE"
        case .step3: return "ONBOARDING_STEP_3_TITLE"
        case .step4: return "ONBOARDING_STEP_4_TITLE"
        case .step5: return "ONBOARDING_STEP_5_TITLE"
        }
    }

    var bodyKey: LocalizedStringKey {
        switch self {
        case .welcome: return "ONBOARDING_WELCOME_BODY"
        case .step1: return "ONBOARDING_STEP_1_BODY"
        case .step2: return "ONBOARDING_STEP_2_BODY"
        case .step3: return "ONBOARDING_STEP_3_BODY"
        case .step4: return "ONBOARDING_STEP_4_BODY"
        case .step5: return "ONBOARDING_STEP_5_BODY"
        }
    }

    /// Asset-catalog name of the step screenshot; nil on welcome.
    var imageName: String? { stepNumber.map { "onboarding-step-\($0)" } }

    var accessibilityIdentifier: String {
        self == .welcome ? "onboarding.page.welcome" : "onboarding.page.step\(stepNumber!)"
    }
}

struct OnboardingWelcomePage: View {
    /// True only while this is the visible page.
    var isActive: Bool = true


    private func bullet(_ destination: FilterDestination, _ textKey: LocalizedStringKey) -> some View {
        let category = destination.category
        return HStack(spacing: 14) {
            Image(systemName: category.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(category.tint)
                .frame(width: 32, height: 32)
                .background(Circle().fill(category.tint.opacity(0.18)))
                // Decorative: without this VoiceOver reads the raw SF Symbol
                // name ("bin.xmark") before the line it decorates.
                .accessibilityHidden(true)
            Text(textKey)
                .font(.subheadline)
                .foregroundStyle(OnboardingStyle.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                content
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var content: some View {
        VStack(spacing: OnboardingStyle.contentSpacing) {
                // The product in one moving picture: mail queues, the door
                // rules on it, junk is turned away.
                DoorScene(presence: .hero, isActive: isActive)
                    .frame(height: 150)
                    .mask {
                        LinearGradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 0.16),
                            .init(color: .black, location: 0.80),
                            .init(color: .clear, location: 1.0),
                        ], startPoint: .top, endPoint: .bottom)
                    }
                    .padding(.horizontal, -OnboardingStyle.pageHorizontalPadding)
                Text("ONBOARDING_WELCOME_TITLE")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(OnboardingStyle.textPrimary)
                    .multilineTextAlignment(.center)
                Text("ONBOARDING_WELCOME_BODY")
                    .font(.body)
                    .foregroundStyle(OnboardingStyle.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 16) {
                    bullet(.junk, "ONBOARDING_BULLET_JUNK")
                    bullet(.allow, "ONBOARDING_BULLET_ALLOW")
                    bullet(.transactionOrder, "ONBOARDING_BULLET_CATEGORIES")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, OnboardingStyle.bulletInset)
                .padding(.trailing, 4)
                .padding(.top, 12)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, OnboardingStyle.pageHorizontalPadding)
            .padding(.vertical, 8)
            .accessibilityIdentifier("onboarding.page.welcome")
    }
}

struct OnboardingStepPage: View {
    let page: OnboardingPage

    private var stepCounter: String {
        String.localizedStringWithFormat(
            NSLocalizedString("ONBOARDING_STEP_COUNTER %1$d %2$d", comment: "Step N of M"),
            page.stepNumber ?? 0,
            OnboardingPage.stepCount
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(stepCounter)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(OnboardingStyle.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(OnboardingStyle.surfaceFill))
                    .overlay(Capsule().strokeBorder(Stage.cardStroke, lineWidth: 1))
                Text(page.titleKey)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(OnboardingStyle.textPrimary)
                    .multilineTextAlignment(.center)
                Text(page.bodyKey)
                    .font(.body)
                    .foregroundStyle(OnboardingStyle.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                // The screenshot is the instruction, so give it the room.
                DeviceFrameView(page: page)
                    .frame(maxHeight: 420)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, OnboardingStyle.pageHorizontalPadding)
            .accessibilityIdentifier(page.accessibilityIdentifier)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct OnboardingPage_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            OnboardingBackdrop()
            OnboardingWelcomePage()
        }
        .previewDisplayName("Welcome")

        ZStack {
            OnboardingBackdrop()
            OnboardingStepPage(page: .step3)
        }
        .previewDisplayName("Step 3")
    }
}
