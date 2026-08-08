//
//  BackgroundView.swift
//  Bouncer
//
//  Bouncer's stage. The app is a doorway: a room with a single light on the
//  door. Everything else — cards, chips, controls — is lit by it.
//
//  The room follows the system appearance. It used to be pinned dark, which
//  made light mode identical to dark mode; the identity is the slate tint and
//  the single light source, not the absence of light.
//

import SwiftUI

// MARK: - Stage

enum Stage {

    /// A colour that resolves per appearance. Wrapping `UIColor` rather than
    /// branching on `@Environment(\.colorScheme)` means these work inside
    /// `Canvas`, `UIKit` and previews without any of them having to care.
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// The room, top to bottom. Slate in both appearances, so the brand reads
    /// the same either way.
    // Light mode is a room with the lights on, not a sheet of paper: still
    // slate, still tinted, just lit. White cards then have something to sit on.
    static let top = adaptive(light: Color(red: 0.894, green: 0.910, blue: 0.941),   // #E4E8F0
                              dark: Color(red: 0.157, green: 0.184, blue: 0.239))   // #282F3D
    static let bottom = adaptive(light: Color(red: 0.804, green: 0.827, blue: 0.875), // #CDD3DF
                                 dark: Color(red: 0.063, green: 0.075, blue: 0.098)) // #101319

    /// Surfaces standing on the stage.
    static let card = adaptive(light: .white, dark: Color.white.opacity(0.055))
    // Hairlines only. On a light stage a black stroke reads far heavier than
    // the same value of white does on a dark one, so the light side is pulled
    // well back and the card is left to separate by fill instead.
    static let cardStroke = adaptive(light: Color.black.opacity(0.045),
                                     dark: Color.white.opacity(0.09))
    static let cardStrokeLit = adaptive(light: Color.black.opacity(0.075),
                                        dark: Color.white.opacity(0.16))
    static let well = adaptive(light: Color.black.opacity(0.045),
                               dark: Color.white.opacity(0.08))

    static let label = adaptive(light: Color(red: 0.09, green: 0.11, blue: 0.15), dark: .white)
    static let secondary = adaptive(light: Color.black.opacity(0.52),
                                    dark: Color.white.opacity(0.64))
    /// Caption text. Anything fainter than this fails AA at caption size.
    static let tertiary = adaptive(light: Color.black.opacity(0.44),
                                   dark: Color.white.opacity(0.55))
    /// Chevrons, hairlines, disclosure marks — never text.
    static let quaternary = adaptive(light: Color.black.opacity(0.20),
                                     dark: Color.white.opacity(0.32))

    /// Legible against `Brand.tint` used as a solid fill. The tint lightens for
    /// dark mode, so the readable pairing flips with it.
    static let onTint = adaptive(light: .white, dark: Color(red: 0.063, green: 0.075, blue: 0.098))

    /// Matches the foot of the room, for fading content under a floating bar.
    static let bottomFade = bottom

    /// Drop shadows have to be softer on a light stage, where a heavy one reads
    /// as dirt rather than as depth.
    static var isDarkFallbackShadow: Double { 0.12 }

    /// A category tint softened into a fill. The light hues are far denser than
    /// their dark counterparts, so the same opacity lands much heavier and each
    /// side needs its own value.
    static func fill(_ tint: Color, weight: Double = 1) -> Color {
        adaptive(light: tint.opacity(0.12 * weight), dark: tint.opacity(0.22 * weight))
    }

    /// The matching hairline for `fill`.
    static func edge(_ tint: Color) -> Color {
        adaptive(light: tint.opacity(0.22), dark: tint.opacity(0.45))
    }

    /// The light source in the door scene: white in a dark room, ink in a light
    /// one. Drawn into a `Canvas`, so it has to be a resolvable colour.
    static let beam = adaptive(light: Color(red: 0.16, green: 0.20, blue: 0.28),
                               dark: .white)
}

/// The room. A vertical wash with a narrow highlight along the top edge.
struct BackgroundView: View {
    var body: some View {
        LinearGradient(colors: [Stage.top, Stage.bottom],
                       startPoint: .top, endPoint: .bottom)
            .overlay(alignment: .top) {
                LinearGradient(colors: [Stage.adaptive(light: Color.white.opacity(0.4),
                                                       dark: Color.white.opacity(0.06)),
                                        .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 180)
            }
            .ignoresSafeArea()
    }
}

// MARK: - Materials

extension View {

    /// The standard raised surface: a slab with a hairline that catches the
    /// light along its top edge.
    func stageCard(cornerRadius: CGFloat = Metrics.cardRadius) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Stage.card)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Stage.cardStroke,
                                                Stage.cardStroke.opacity(0.3)],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 1)
            }
    }
}

#Preview {
    ZStack {
        BackgroundView()
        VStack(spacing: 16) {
            Text("Rules").font(.largeTitle.bold()).foregroundStyle(Stage.label)
            Text("Card").foregroundStyle(Stage.label)
                .frame(maxWidth: .infinity).padding()
                .stageCard()
        }
        .padding()
    }
}
