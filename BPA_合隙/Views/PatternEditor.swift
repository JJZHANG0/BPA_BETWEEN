import SwiftUI

struct PatternEditor: View {
    @Environment(ConnectionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var pulses: [Double] = [0.18, 0.45, 0.18]
    @State private var preview = HapticPreview()
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "A touch that sounds like you", title: "Your own quiet rhythm.", subtitle: "Combine up to six pulses. A short pause separates each one.")
            Surface {
                VStack(spacing: 28) {
                    HStack(alignment: .center, spacing: 12) {
                        ForEach(Array(pulses.enumerated()), id: \.offset) { index, duration in
                            VStack(spacing: 12) {
                                Capsule().fill(Palette.text).frame(width: max(12, duration * 38), height: 50 + duration * 36)
                                Text("\(index + 1)").font(.system(size: 10)).foregroundStyle(Palette.secondary)
                            }.frame(maxWidth: .infinity)
                        }
                    }.frame(height: 115)
                    Text("\(pulses.count) pulses · \(pulses.reduce(0, +) + Double(max(0, pulses.count - 1)) * 0.18, specifier: "%.1f") seconds")
                        .font(.system(size: 12)).foregroundStyle(Palette.secondary)
                }
            }
            ForEach(pulses.indices, id: \.self) { index in
                HStack(spacing: 15) {
                    Text("Pulse \(index + 1)").font(.system(size: 13)).frame(width: 55, alignment: .leading)
                    Slider(value: $pulses[index], in: 0.1...0.8, step: 0.05).tint(Palette.text)
                    Text("\(pulses[index], specifier: "%.2f")s").font(.system(size: 11, design: .monospaced)).foregroundStyle(Palette.secondary).frame(width: 44)
                }
            }
            HStack {
                Button { if pulses.count < 6 { pulses.append(0.18) } } label: { Label("Add pulse", systemImage: "plus").font(.system(size: 13)) }.disabled(pulses.count >= 6)
                Spacer()
                Button { if pulses.count > 1 { pulses.removeLast() } } label: { Label("Remove", systemImage: "minus").font(.system(size: 13)) }.disabled(pulses.count <= 1)
            }.frame(minHeight: 44)
            Button {
                // Preview the draft without persisting it until Save.
                preview.play(pulses)
            } label: {
                Label("Preview on this iPhone", systemImage: "play").font(.system(size: 14)).frame(maxWidth: .infinity, minHeight: 50)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.line))
            }
            PrimaryButton(title: "Save your touch", icon: "checkmark") { store.customPattern = pulses; dismiss() }
            DemoFootnote(text: "The phone preview represents pulse rhythm using iPhone feedback. Actual motor timing and intensity depend on future firmware support.")
        }.onAppear { pulses = store.customPattern }
            .onDisappear { preview.stop() }
    }
}
