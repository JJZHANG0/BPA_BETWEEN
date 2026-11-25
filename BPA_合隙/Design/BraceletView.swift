import SwiftUI

/// Procedural product illustration: a concept enclosure, not a representation of verified hardware.
struct BraceletView: View {
    var color: Color = Emotion.calm.color
    var rotation: Double = -28
    var lit = true
    var body: some View {
        ZStack {
            Ellipse().fill(Color.black.opacity(0.35)).blur(radius: 15).offset(x: 5, y: 25)
            Ellipse().stroke(Color.black, lineWidth: 34)
            Ellipse().stroke(
                LinearGradient(stops: [.init(color: Color(hex: 0x70747A), location: 0), .init(color: Color(hex: 0x303339), location: 0.20), .init(color: Color(hex: 0x111317), location: 0.48), .init(color: Color(hex: 0x393D44), location: 0.76), .init(color: Color(hex: 0x777B80), location: 1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 29)
            Ellipse().inset(by: -15).stroke(Color.white.opacity(0.17), lineWidth: 0.8)
            Ellipse().inset(by: 14).stroke(Color.black.opacity(0.9), lineWidth: 2)
            Ellipse().inset(by: 12).trim(from: 0.44, to: 0.94).stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            Ellipse().trim(from: 0.53, to: 0.84).stroke(Color.black.opacity(0.8), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            Ellipse().trim(from: 0.55, to: 0.82).stroke(lit ? color.opacity(0.35) : .clear, style: StrokeStyle(lineWidth: 10, lineCap: .round)).blur(radius: 7)
            Ellipse().trim(from: 0.55, to: 0.82).stroke(lit ? color : Color(hex: 0x44474D), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            Ellipse().trim(from: 0.56, to: 0.81).stroke(lit ? Color.white.opacity(0.45) : .clear, lineWidth: 0.8)
            Capsule().fill(Color(hex: 0x555960)).frame(width: 23, height: 5).overlay(Capsule().stroke(Color.black.opacity(0.6), lineWidth: 1)).offset(y: 98)
        }
        .frame(width: 128, height: 206)
        .rotationEffect(.degrees(rotation))
        .accessibilityLabel(lit ? "Bracelet with emotional light" : "Disconnected bracelet")
    }
}

struct BraceletPair: View {
    let emotion: Emotion
    var connected = true
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Ellipse().stroke(Palette.line, lineWidth: 0.6).frame(width: 310, height: 105).rotationEffect(.degrees(-20)).offset(y: 20)
                BraceletView(color: emotion.color, rotation: -32, lit: connected).offset(x: -57, y: -8)
                BraceletView(color: Emotion.missing.color, rotation: 30, lit: connected).offset(x: 60, y: 22)
            }.frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(min(proxy.size.width / 345, 1))
        }.frame(height: 270)
            .animation(.easeInOut(duration: 0.5), value: emotion)
    }
}

struct ConnectionThread: View {
    var connected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle().fill(Palette.line).frame(height: 1)
                if connected {
                    Circle().fill(Palette.text).frame(width: 4, height: 4)
                        .offset(x: reduceMotion ? 0 : (animate ? geo.size.width / 2 - 3 : -geo.size.width / 2 + 3))
                }
            }.frame(height: geo.size.height)
        }.frame(height: 24)
            .onAppear {
                if !reduceMotion { withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { animate = true } }
            }.accessibilityHidden(true)
    }
}
