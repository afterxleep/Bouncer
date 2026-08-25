//
//  DoorScene.swift
//  Bouncer
//
//  Bouncer's signature: the door.
//
//  Messages fall straight down past a lit threshold. Ones you allow pass
//  through and keep going, all the way to the end of the road before they
//  fade — that's the whole palette here: safe ships blue-green, junk fades
//  away right at the line in red. Every bubble travels a plain vertical line;
//  only its lane, size and timing are randomised, and only a handful are ever
//  on screen at once. It runs live behind the rules header and full-size on
//  the welcome screen, so the product explains itself before a word is read.
//
//  Drawn in a single `Canvas` inside a `TimelineView` — one draw call per
//  frame, no view churn, and every bubble's path is a pure function of time so
//  there is no simulation state to keep in sync.
//

import SwiftUI

// MARK: - Verdict

private enum Verdict {
    case allow
    case sorted(Color)
    case junk

    var tint: Color {
        switch self {
        case .allow: return Brand.safe
        case .sorted(let color): return color
        case .junk: return Brand.junk
        }
    }
}

// MARK: - Bubble

/// One message. Everything about it is fixed at build time; only `time` moves.
private struct Bubble {
    let lane: Double        // 0...1 across the width — fixed for the whole run, no sideways travel
    let speed: Double       // runs per second
    let phase: Double       // offset so they don't march in step
    let depth: Double       // 0 = far (small, dim, slow), 1 = near
    let width: Double       // relative bubble width
    let verdict: Verdict

    /// Fraction of the run spent travelling before a clean pass sits at the
    /// end of the road; the rest is spent fading there, not fading en route.
    private let roadEnd = 0.82

    /// Where the bubble is, and how it looks, at a point in its run.
    /// `p` is 0...1. Y is normalised with 0 at the top of the scene. Every
    /// verdict falls the same straight vertical line — only where it ends up,
    /// and when it fades, differs.
    func state(at p: Double, thresholdY: Double) -> (x: Double, y: Double, opacity: Double, flare: Double) {
        switch verdict {
        case .allow, .sorted:
            // A clean pass: falls from above the frame all the way to the end
            // of the road at full strength, and only fades once it's arrived.
            let travel = min(p, roadEnd) / roadEnd
            let y = -0.12 + eased(travel) * 1.12
            let fadeIn = ramp(p, in: 0.00, out: 0.08)
            let fadeOut = p < roadEnd ? 1.0 : 1 - ramp(p, in: roadEnd, out: 1.00)
            return (lane, y, fadeIn * fadeOut, 0)

        case .junk:
            // Falls toward the line, stops short of it, and dissolves there —
            // position and fade are decoupled so it's fully gone well before
            // it would ever touch the line, never mind cross it.
            let stopY = thresholdY - 0.08
            let approachEnd = 0.78
            let travel = min(p, approachEnd) / approachEnd
            let y = -0.12 + eased(travel) * (stopY + 0.12)
            let fadeIn = ramp(p, in: 0.00, out: 0.08)
            let fadeOut = p < approachEnd ? 1.0 : 1 - ramp(p, in: approachEnd, out: 1.00)
            let flareStart = approachEnd
            let flarePeak = approachEnd + 0.06
            let flare = ramp(p, in: flareStart, out: flarePeak) * (1 - ramp(p, in: flarePeak, out: 1.00))
            return (lane, y, fadeIn * fadeOut, flare)
        }
    }

    /// Smoothstep in/out so nothing pops at the edges of the frame.
    private func ramp(_ v: Double, in start: Double, out end: Double) -> Double {
        guard end > start else { return 1 }
        return min(1, max(0, (v - start) / (end - start)))
    }

    private func eased(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
}

// MARK: - Scene

struct DoorScene: View {

    /// How loud the scene is. The welcome screen runs it as the hero; the rules
    /// header runs it dialled back so type stays the loudest thing on screen.
    enum Presence {
        case hero
        case ambient

        var bubbleCount: Int { self == .hero ? 11 : 9 }
        /// The line sits high in the ambient band so messages have room to
        /// fall into it, and the verdict lands just above the masthead.
        var thresholdY: Double { self == .hero ? 0.46 : 0.44 }
        var opacity: Double { self == .hero ? 1.0 : 0.8 }
        var lineWidth: Double { self == .hero ? 1.2 : 1.0 }
        var scale: Double { self == .hero ? 0.72 : 0.8 }
    }

    var presence: Presence = .hero
    /// Whether the scene is the page on screen. A `TabView` keeps its pages
    /// alive, so without this the canvas carried on redrawing at display rate
    /// behind every step of the walkthrough.
    var isActive: Bool = true

    /// A fixed cast, seeded so the scene is identical on every launch — the
    /// composition was tuned by eye and shouldn't reshuffle.
    private var bubbles: [Bubble] {
        var generator = SeededGenerator(seed: 0xB0_9C_E7_11)
        // Just the two colours that ship, plus junk red — no other hues.
        let hues: [Color] = [Brand.orders]
        return (0..<presence.bubbleCount).map { index in
            let roll = Double.random(in: 0...1, using: &generator)
            let verdict: Verdict
            // Junk is the common case at a real door, and the fade at the
            // line is the part worth showing — so it gets the largest share.
            if roll < 0.46 {
                verdict = .junk
            } else if roll < 0.70 {
                verdict = .allow
            } else {
                verdict = .sorted(hues[index % hues.count])
            }
            let depth = Double.random(in: 0.25...1, using: &generator)
            return Bubble(
                lane: Double.random(in: 0.08...0.92, using: &generator),
                speed: (0.055 + Double.random(in: 0...0.05, using: &generator)) * (0.6 + depth * 0.7),
                phase: Double.random(in: 0...1, using: &generator),
                depth: depth,
                width: 0.070 + Double.random(in: 0...0.055, using: &generator),
                verdict: verdict
            )
        }
    }

    var body: some View {
        let cast = bubbles
        TimelineView(.animation(paused: !isActive)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let thresholdY = presence.thresholdY

                drawBubbles(cast, in: &context, size: size, time: t, thresholdY: thresholdY)
                drawThreshold(in: &context, size: size, y: thresholdY)
            }
            .drawingGroup()
        }
        .opacity(presence.opacity)
        .accessibilityHidden(true)
    }
}

// MARK: - Shape

extension DoorScene {

    /// An incoming message balloon: rounded body with a tail hooking off the
    /// bottom-left, traced as a single unbroken outline so the tail always
    /// meets the body with no seam or gap, at any size.
    static func bubble(in rect: CGRect) -> Path {
        let radius = min(rect.height * 0.48, rect.width * 0.42)
        let tailLength = rect.height * 0.34
        let body = CGRect(x: rect.minX + tailLength * 0.6,
                          y: rect.minY,
                          width: max(rect.width - tailLength * 0.6, 1),
                          height: rect.height)

        // Anchors sit on the body's own straight edges, safely clear of the
        // bottom-left corner, so the tail always attaches to solid geometry
        // rather than approximating where a separate corner curve would be.
        let leftAnchor = CGPoint(x: body.minX, y: body.maxY - radius * 1.15)
        let bottomAnchor = CGPoint(x: body.minX + radius * 1.15, y: body.maxY)
        let tip = CGPoint(x: rect.minX, y: rect.maxY)

        var path = Path()
        path.move(to: CGPoint(x: body.minX, y: body.minY + radius))
        path.addArc(center: CGPoint(x: body.minX + radius, y: body.minY + radius),
                    radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY))
        path.addArc(center: CGPoint(x: body.maxX - radius, y: body.minY + radius),
                    radius: radius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radius))
        path.addArc(center: CGPoint(x: body.maxX - radius, y: body.maxY - radius),
                    radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: bottomAnchor)
        // The tail takes the place of the bottom-left corner entirely, rather
        // than a separate shape laid over it.
        path.addQuadCurve(to: tip, control: CGPoint(x: body.minX + tailLength * 0.35, y: body.maxY))
        path.addQuadCurve(to: leftAnchor,
                          control: CGPoint(x: body.minX - tailLength * 0.05, y: body.maxY - radius * 0.1))
        path.addLine(to: CGPoint(x: body.minX, y: body.minY + radius))
        path.closeSubpath()
        return path
    }
}

// MARK: - Drawing

private extension DoorScene {

    func drawBubbles(_ cast: [Bubble],
                     in context: inout GraphicsContext,
                     size: CGSize,
                     time: Double,
                     thresholdY: Double) {
        for bubble in cast {
            let p = (time * bubble.speed + bubble.phase).truncatingRemainder(dividingBy: 1)
            let state = bubble.state(at: p, thresholdY: thresholdY)
            guard state.opacity > 0.01, state.y > -0.2, state.y < 1.3 else { continue }

            let w = bubble.width * presence.scale * size.width * (0.55 + bubble.depth * 0.65)
            let h = w * 0.66
            let origin = CGPoint(x: state.x * size.width - w / 2,
                                 y: state.y * size.height - h / 2)
            let rect = CGRect(origin: origin, size: CGSize(width: w, height: h))
            let shape = Self.bubble(in: rect)

            let tint = bubble.verdict.tint
            let alpha = state.opacity * (0.22 + bubble.depth * 0.42)

            if state.flare > 0 {
                // A brief flash as a junk bubble dissolves at the line, not a
                // standing halo — the rest of the app has no coloured glows.
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: h * 0.45))
                    layer.fill(shape, with: .color(tint.opacity(state.flare * 0.55)))
                }
            }

            context.fill(shape, with: .color(tint.opacity(alpha)))
            context.stroke(shape,
                           with: .color(tint.opacity(alpha * 0.9)),
                           lineWidth: 0.75)
        }
    }

    /// A thin, quiet line — just enough to read as the threshold junk fades
    /// away at, without competing with the bubbles or the type above it.
    func drawThreshold(in context: inout GraphicsContext, size: CGSize, y: Double) {
        let lineY = y * size.height
        let inset = size.width * 0.14
        let line = Path { path in
            path.move(to: CGPoint(x: inset, y: lineY))
            path.addLine(to: CGPoint(x: size.width - inset, y: lineY))
        }
        let gradient = Gradient(stops: [
            .init(color: Brand.tint.opacity(0.0), location: 0.0),
            .init(color: Brand.tint.opacity(0.28), location: 0.5),
            .init(color: Brand.tint.opacity(0.0), location: 1.0),
        ])
        context.stroke(
            line,
            with: .linearGradient(gradient,
                                  startPoint: CGPoint(x: inset, y: lineY),
                                  endPoint: CGPoint(x: size.width - inset, y: lineY)),
            lineWidth: presence.lineWidth)
    }
}

// MARK: - Deterministic randomness

/// A tiny SplitMix64 so the cast is the same every launch.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

#Preview("Hero") {
    ZStack {
        BackgroundView()
        DoorScene(presence: .hero)
    }
}

#Preview("Ambient") {
    ZStack {
        BackgroundView()
        DoorScene(presence: .ambient).frame(height: 200)
    }
}
