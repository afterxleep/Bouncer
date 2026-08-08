//
//  DoorScene.swift
//  Bouncer
//
//  Bouncer's signature: the door.
//
//  Messages drift up toward a lit threshold. Ones you allow pass through and
//  keep going. Junk hits the line, flares, and is turned away. Categorised mail
//  passes but veers off to be filed. It runs live behind the rules header and
//  full-size on the welcome screen, so the product explains itself before a
//  word is read.
//
//  Drawn in a single `Canvas` inside a `TimelineView` — one draw call per
//  frame, no view churn, and every bubble's path is a pure function of time so
//  there is no simulation state to keep in sync.
//

import SwiftUI

// MARK: - Verdict

private enum Verdict {
    case allow
    case junk
    case sorted(Color)

    var tint: Color {
        switch self {
        case .allow: return Brand.safe
        case .junk: return Brand.junk
        case .sorted(let color): return color
        }
    }
}

// MARK: - Bubble

/// One message. Everything about it is fixed at build time; only `time` moves.
private struct Bubble {
    let lane: Double        // 0...1 across the width
    let drift: Double       // sideways travel over the run
    let speed: Double       // runs per second
    let phase: Double       // offset so they don't march in step
    let depth: Double       // 0 = far (small, dim, slow), 1 = near
    let width: Double       // relative bubble width
    let verdict: Verdict

    /// Where the bubble is, and how it looks, at a point in its run.
    /// `p` is 0...1. Y is normalised with 0 at the top of the scene.
    func state(at p: Double, thresholdY: Double) -> (x: Double, y: Double, opacity: Double, flare: Double) {
        switch verdict {
        case .allow, .sorted:
            // A clean pass: rise from below the frame and out through the top.
            let y = 1.12 - p * 1.24
            let veer: Double
            if case .sorted = verdict {
                // Filed away: once past the door it slides toward its shelf.
                let past = max(0, (thresholdY - y) / max(thresholdY, 0.001))
                veer = drift * past * past
            } else {
                veer = drift * p * 0.35
            }
            let fade = ramp(p, in: 0.00, out: 0.10) * ramp(1 - p, in: 0.00, out: 0.18)
            return (lane + veer, y, fade, 0)

        case .junk:
            // Turned away: up to the line, a flare, then pushed back down.
            let turn = 0.52
            if p < turn {
                let t = p / turn
                let y = 1.12 - eased(t) * (1.12 - thresholdY)
                return (lane + drift * t * 0.2, y, ramp(p, in: 0, out: 0.08), 0)
            } else {
                let t = (p - turn) / (1 - turn)
                let y = thresholdY + eased(t) * 0.75
                let flare = max(0, 1 - t * 5)
                return (lane + drift * (0.2 + t * 1.5), y, 1 - t * t, flare)
            }
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

        var bubbleCount: Int { self == .hero ? 18 : 15 }
        /// The line sits high in the ambient band so messages have room to rise
        /// into it, and the verdict lands just above the masthead.
        var thresholdY: Double { self == .hero ? 0.46 : 0.44 }
        var opacity: Double { self == .hero ? 1.0 : 0.8 }
        var lineWidth: Double { self == .hero ? 1.6 : 1.2 }
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
        let hues: [Color] = [Brand.orders, Brand.offers, Brand.finance, Brand.coupons, Brand.reminders]
        return (0..<presence.bubbleCount).map { index in
            let roll = Double.random(in: 0...1, using: &generator)
            let verdict: Verdict
            // Junk is the common case at a real door, and the flare is the part
            // worth showing — so it gets the largest share.
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
                drift: Double.random(in: -0.22...0.22, using: &generator),
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
                drawThreshold(in: &context, size: size, time: t, y: thresholdY)
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
    /// bottom-left. These are meant to read as texts arriving, and a plain
    /// rounded rectangle read as a lozenge.
    static func bubble(in rect: CGRect) -> Path {
        let radius = min(rect.height * 0.48, rect.width * 0.42)
        let tail = rect.height * 0.34
        let body = CGRect(x: rect.minX + tail * 0.6,
                          y: rect.minY,
                          width: max(rect.width - tail * 0.6, 1),
                          height: rect.height)

        var path = Path(roundedRect: body,
                        cornerSize: CGSize(width: radius, height: radius),
                        style: .continuous)

        var hook = Path()
        hook.move(to: CGPoint(x: body.minX + radius * 0.05, y: body.maxY - radius * 0.85))
        hook.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                          control: CGPoint(x: body.minX - tail * 0.05, y: body.maxY - radius * 0.1))
        hook.addQuadCurve(to: CGPoint(x: body.minX + radius * 1.05, y: body.maxY),
                          control: CGPoint(x: body.minX + tail * 0.35, y: rect.maxY))
        hook.closeSubpath()
        path.addPath(hook)
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

            // Before the door every message is anonymous; the colour is the
            // verdict, so it only appears once the door has ruled. Queueing
            // messages are dimmer than judged ones, so the eye is pulled to the
            // line rather than to the crowd.
            // Queueing messages carry the brand tint rather than neutral grey:
            // grey lozenges on a dark field read as a loading skeleton.
            let ruled = state.y <= thresholdY + 0.01
            let tint = ruled ? bubble.verdict.tint : Brand.tint
            let alpha = state.opacity * (0.22 + bubble.depth * 0.42) * (ruled ? 1.4 : 1.0)

            if state.flare > 0 {
                // A brief flash at the moment of the verdict, not a standing
                // halo — the rest of the app has no coloured glows.
                context.drawLayer { layer in
                    layer.addFilter(.blur(radius: h * 0.45))
                    layer.fill(shape, with: .color(bubble.verdict.tint.opacity(state.flare * 0.55)))
                }
            }

            context.fill(shape, with: .color(tint.opacity(alpha)))
            context.stroke(shape,
                           with: .color(tint.opacity(alpha * 0.9)),
                           lineWidth: 0.75)
        }
    }

    /// The threshold: a hard bright core with a wide bloom, and a highlight that
    /// sweeps along it so the door reads as live rather than painted on.
    func drawThreshold(in context: inout GraphicsContext,
                       size: CGSize,
                       time: Double,
                       y: Double) {
        let lineY = y * size.height
        let inset = size.width * 0.14
        let line = Path { path in
            path.move(to: CGPoint(x: inset, y: lineY))
            path.addLine(to: CGPoint(x: size.width - inset, y: lineY))
        }

        // Bloom.
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 12))
            layer.stroke(line, with: .color(Stage.beam.opacity(0.18)), lineWidth: 4)
        }

        // Core, fading out at both ends so it reads as light rather than a rule.
        let gradient = Gradient(stops: [
            .init(color: Stage.beam.opacity(0.0), location: 0.0),
            .init(color: Stage.beam.opacity(0.55), location: 0.5),
            .init(color: Stage.beam.opacity(0.0), location: 1.0),
        ])
        context.stroke(
            line,
            with: .linearGradient(gradient,
                                  startPoint: CGPoint(x: inset, y: lineY),
                                  endPoint: CGPoint(x: size.width - inset, y: lineY)),
            lineWidth: presence.lineWidth)

        // Sweeping highlight.
        let travel = (time * 0.18).truncatingRemainder(dividingBy: 1)
        let centre = inset + travel * (size.width - inset * 2)
        let span = size.width * 0.22
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 6))
            layer.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centre - span / 2, y: lineY))
                    path.addLine(to: CGPoint(x: centre + span / 2, y: lineY))
                },
                with: .linearGradient(
                    Gradient(colors: [Stage.beam.opacity(0), Stage.beam.opacity(0.85),
                                      Stage.beam.opacity(0)]),
                    startPoint: CGPoint(x: centre - span / 2, y: lineY),
                    endPoint: CGPoint(x: centre + span / 2, y: lineY)),
                lineWidth: presence.lineWidth * 2.2)
        }
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
