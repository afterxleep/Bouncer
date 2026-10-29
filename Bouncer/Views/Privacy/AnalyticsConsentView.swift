//
//  AnalyticsConsentView.swift
//  Bouncer
//

import SwiftUI

/// Asked once, before anything is measured: new installs see it over the
/// welcome page, and people who had the app before analytics existed see it on
/// their next launch. Both answers are equally easy to give and equally final
/// until changed in Help.
struct AnalyticsConsentView: View {
    let onChoice: (AnalyticsConsent) -> Void

    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Metrics.xl) {
                        hero
                        VStack(spacing: 0) {
                            point(symbol: "hand.raised.slash.fill", tint: Brand.safe,
                                  title: "PRIVACY_NO_TRACKING_TITLE", body: "PRIVACY_NO_TRACKING_BODY")
                            divider
                            point(symbol: "iphone.gen3", tint: Brand.tint,
                                  title: "PRIVACY_ON_DEVICE_TITLE", body: "PRIVACY_ON_DEVICE_BODY")
                            divider
                            point(symbol: "chart.bar.fill", tint: Brand.tint,
                                  title: "PRIVACY_USAGE_TITLE", body: "PRIVACY_USAGE_BODY")
                        }
                        .stageCard()
                    }
                    .padding(.horizontal, Metrics.l)
                    .padding(.top, Metrics.xxl)
                    .padding(.bottom, Metrics.l)
                }
                .scrollIndicators(.hidden)
                buttons
            }
        }
        .tint(Brand.tint)
    }

    private var hero: some View {
        VStack(spacing: Metrics.m) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Brand.tint)
                .frame(width: 76, height: 76)
                .background(Circle().fill(Brand.tint.opacity(0.16)))
                .accessibilityHidden(true)
            Text("PRIVACY_TITLE")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Stage.label)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text("PRIVACY_SUBTITLE")
                .font(.subheadline)
                .foregroundStyle(Stage.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var divider: some View {
        Divider().padding(.leading, Metrics.l + 36 + Metrics.m)
    }

    private func point(symbol: String, tint: Color,
                       title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: Metrics.m) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(Circle().fill(tint.opacity(0.16)))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Stage.label)
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(Stage.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Metrics.l)
        .accessibilityElement(children: .combine)
    }

    private var buttons: some View {
        VStack(spacing: Metrics.m) {
            Button { onChoice(.granted) } label: {
                Text("PRIVACY_ACCEPT")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Stage.onTint)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(Brand.tint))
            }
            .accessibilityIdentifier("privacy.accept")

            Button { onChoice(.denied) } label: {
                Text("PRIVACY_DECLINE")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Stage.label)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(Stage.card))
                    .overlay(Capsule().strokeBorder(Stage.cardStroke, lineWidth: 1))
            }
            .accessibilityIdentifier("privacy.decline")

            Text("PRIVACY_CHANGE_ANYTIME")
                .font(.caption)
                .foregroundStyle(Stage.tertiary)
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Metrics.l)
        .padding(.top, Metrics.m)
        .padding(.bottom, Metrics.l)
    }
}

#Preview {
    AnalyticsConsentView { _ in }
}
