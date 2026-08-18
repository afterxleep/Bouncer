//
//  OnboardingComponents.swift
//  Bouncer
//

import SwiftUI

enum OnboardingStyle {
    /// The app's blue, sampled from the welcome mark (#51627D).
    static let accent = Color(red: 0.318, green: 0.384, blue: 0.490)
    /// The navigation-bar blue (#3C4451) — the app's header.
    static let accentDeep = Color(red: 0.235, green: 0.267, blue: 0.318)
    /// The launch-screen blue (#1A2229) — the app's splash background.
    static let splash = Color(red: 0.104, green: 0.131, blue: 0.175)
    /// A lifted tint of the brand blue, for icons on the field.
    static let accentLight = Color(red: 0.66, green: 0.72, blue: 0.82)

    // The same room as the rest of the app. Onboarding used to run on its own
    // lighter blue, so the first thing that happened after "Done" was the
    // background changing colour.
    static let backgroundTop = Stage.top
    static let backgroundBottom = Stage.bottom

    // Onboarding stands on the same stage as the app, so its type follows the
    // system appearance too.
    static let textPrimary = Stage.label
    static let textSecondary = Stage.secondary
    /// Fill for chips, icon wells and secondary controls.
    static let surfaceFill = Stage.well

    static let pageHorizontalPadding: CGFloat = 28
    /// Extra inset for the welcome bullets, so the left-aligned block sits
    /// inside the centred copy above it rather than flush with the page edge.
    static let bulletInset: CGFloat = 14
    static let contentSpacing: CGFloat = 20
    static let frameCornerRadius: CGFloat = 44
}

struct OnboardingBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [OnboardingStyle.backgroundTop, OnboardingStyle.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            LinearGradient(colors: [Stage.adaptive(light: Color.white.opacity(0.4),
                                                   dark: Color.white.opacity(0.06)), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 180)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
        }
    }
}

/// The picture for a step.
///
/// A real screenshot is shown as a plain rounded card, cropped tight to the part
/// of Settings the step is about. There is no phone bezel: at this size a whole
/// device is a stubby rectangle whose corners can never match a real iPhone, and
/// the miniature screen inside it is too small to read. A fragment of a screen,
/// shown large, does the job the picture is there to do.
///
/// Steps without a screenshot fall back to a drawn mock of the same screen.
struct DeviceFrameView: View {
    let page: OnboardingPage

    /// Matches the corner of an iOS grouped-list card, so the crop looks like a
    /// piece of the system rather than a floating image.
    private static let corner: CGFloat = 20

    private var screenshot: UIImage? {
        guard let name = page.imageName else { return nil }
        return UIImage(named: name)
    }

    var body: some View {
        Group {
            if let screenshot {
                Image(uiImage: screenshot)
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    OnboardingStyle.splash
                    OnboardingIllustration(page: page)
                }
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Self.corner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
                .strokeBorder(Stage.cardStroke, lineWidth: 1)
        }
        .shadow(color: .black.opacity(Stage.isDarkFallbackShadow), radius: 22, y: 12)
        // The illustration restates the step copy above it; announcing it
        // again would make VoiceOver read every step twice.
        .accessibilityHidden(true)
    }
}

struct OnboardingPageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { dot in
                Capsule()
                    .fill(dot == index ? Stage.label : Stage.quaternary)
                    .frame(width: dot == index ? 20 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: index)
        .accessibilityHidden(true)
    }
}

struct OnboardingComponents_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            OnboardingBackdrop()
            VStack(spacing: 24) {
                DeviceFrameView(page: .step2)
                    .frame(maxHeight: 420)
                OnboardingPageDots(count: 6, index: 2)
            }
            .padding(OnboardingStyle.pageHorizontalPadding)
        }
    }
}
