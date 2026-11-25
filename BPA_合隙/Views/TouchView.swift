import SwiftUI

struct TouchView: View {
    @Environment(ConnectionStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var sheet: AppSheet?
    @State private var selected: TouchSignal = .thinking
    @State private var ripple = false
    @State private var rippleTask: Task<Void, Never>?
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "Beyond words", title: "Reach out. Feel closer.", subtitle: "For the moments a message can’t quite hold.")
            HStack(spacing: 7) {
                Circle().fill(store.canSend ? Emotion.safe.color : Palette.secondary).frame(width: 5, height: 5)
                Text(store.canSend ? "A touch away from \(store.partnerName)" : "Your connection needs a moment")
                    .font(.system(size: 12)).foregroundStyle(Palette.secondary)
                Spacer()
                Text("DEMO").font(.system(size: 9)).tracking(1).foregroundStyle(Palette.secondary)
            }
            VStack(spacing: 25) {
                ZStack {
                    ForEach(0..<3) { index in
                        Circle().stroke(Palette.text.opacity(ripple ? 0 : 0.04 + Double(index) * 0.025), lineWidth: 0.7)
                            .frame(width: CGFloat(195 + index * 35), height: CGFloat(195 + index * 35))
                            .scaleEffect(ripple && !reduceMotion ? 1.15 : 1)
                    }
                    Circle().fill(RadialGradient(colors: [Color(hex: 0x363A41), Palette.surface, Palette.background], center: .center, startRadius: 0, endRadius: 110)).frame(width: 194, height: 194)
                        .overlay(Circle().stroke(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                    VStack(spacing: 15) {
                        Image(systemName: "hand.tap").font(.system(size: 44, weight: .ultraLight))
                        Text(store.sending ? "SENDING" : "TOUCH & CONNECT").font(.system(size: 8, weight: .medium)).tracking(2)
                    }.foregroundStyle(Palette.text.opacity(0.9))
                }.frame(maxWidth: .infinity).frame(height: 290).contentShape(Circle())
                    .gesture(LongPressGesture(minimumDuration: 0.65).exclusively(before: TapGesture(count: 2).exclusively(before: TapGesture(count: 1))).onEnded { value in
                        switch value {
                        case .first: transmit(.goodnight)
                        case .second(.first): transmit(.here)
                        case .second(.second): transmit(selected)
                        }
                    })
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Send \(selected.title)")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { transmit(selected) }
                    .accessibilityIdentifier("touch.pad")
                VStack(spacing: 9) {
                    Text(selected.title).font(.system(size: 23, weight: .light))
                    PatternBars(pattern: store.pattern(for: selected))
                    Text("Tap to send · double tap for I’m here\nHold for Good night")
                        .font(.system(size: 11)).foregroundStyle(Palette.secondary).lineSpacing(4).multilineTextAlignment(.center)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(TouchSignal.allCases.filter { $0 != .custom }) { signal in
                    Button { selected = signal; store.preview(signal) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: signal.icon).font(.system(size: 17, weight: .light)).frame(width: 22)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(signal.title).font(.system(size: 12, weight: .medium))
                                Text(signal.gesture).font(.system(size: 9)).foregroundStyle(Palette.secondary)
                            }
                            Spacer(minLength: 0)
                        }.padding(14).frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                            .background(selected == signal ? Palette.raised : Palette.surface, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected == signal ? .white.opacity(0.4) : Palette.line, lineWidth: 0.7))
                    }.buttonStyle(.plain).accessibilityAddTraits(selected == signal ? [.isSelected] : [])
                }
            }
            if let delivery = store.latestDelivery {
                HStack(alignment: .top, spacing: 8) {
                    if store.sending { ProgressView().scaleEffect(0.7) } else { Image(systemName: "paperplane") }
                    Text(delivery).fixedSize(horizontal: false, vertical: true)
                }.font(.system(size: 12)).foregroundStyle(Palette.secondary).accessibilityIdentifier("delivery.status")
            }
            HStack(spacing: 12) {
                Button { selected = .custom; sheet = .pattern } label: { Label("Create a touch", systemImage: "slider.horizontal.3").font(.system(size: 12)) }
                Spacer()
                Button { sheet = .history } label: { Text("Your moments ↗").font(.system(size: 12)).foregroundStyle(Palette.secondary) }
            }.frame(minHeight: 44)
            DemoFootnote(text: "Touches are delivered within this demo only. Phone haptics preview the rhythm; bracelet vibration may feel different.")
        }.onDisappear { rippleTask?.cancel() }
    }
    private func transmit(_ signal: TouchSignal) {
        guard !store.sending else { return }
        selected = signal
        store.preview(signal)
        rippleTask?.cancel()
        withAnimation(.easeOut(duration: 0.8)) { ripple = true }
        Task { await store.send(signal) }
        rippleTask = Task {
            try? await Task.sleep(for: .milliseconds(1400))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.4)) { ripple = false }
        }
    }
}

struct PatternBars: View {
    let pattern: [Double]
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(pattern.enumerated()), id: \.offset) { _, duration in
                Capsule().fill(Palette.secondary).frame(width: max(6, duration * 40), height: 4)
            }
        }.frame(height: 15).accessibilityLabel("\(pattern.count) vibration pulses")
    }
}
