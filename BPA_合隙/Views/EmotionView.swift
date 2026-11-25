import SwiftUI

struct EmotionView: View {
    @Environment(ConnectionStore.self) private var store
    @Binding var sheet: AppSheet?
    @State private var editing: Emotion?
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "Your six-color language", title: "How does now feel?", subtitle: "No perfect words needed.\nJust a little honesty, in your own color.")
            VStack(spacing: 13) {
                ZStack {
                    Circle().stroke(store.emotion.color.opacity(0.13), lineWidth: 1).frame(width: 100, height: 100)
                    Circle().stroke(store.emotion.color.opacity(0.25), lineWidth: 1).frame(width: 77, height: 77)
                    Circle().fill(store.emotion.color).frame(width: 48, height: 48)
                        .shadow(color: store.emotion.color.opacity(0.12), radius: 20)
                }.padding(.top, 7)
                Text(store.label(for: store.emotion)).font(.system(size: 25, weight: .light))
                Text(store.emotion.message).font(.system(size: 12)).foregroundStyle(Palette.secondary).multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity).animation(.easeInOut(duration: 0.35), value: store.emotion)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 23) {
                ForEach(Emotion.allCases) { emotion in
                    Button { withAnimation { store.selectEmotion(emotion) } } label: {
                        VStack(spacing: 12) {
                            Circle().fill(emotion.color).frame(width: 35, height: 35)
                                .padding(9).overlay(Circle().stroke(store.emotion == emotion ? emotion.color : .clear, lineWidth: 1))
                                .overlay { if store.emotion == emotion { Image(systemName: "checkmark").font(.system(size: 12, weight: .medium)).foregroundStyle(Palette.background) } }
                            Text(store.label(for: emotion)).font(.system(size: 12)).foregroundStyle(store.emotion == emotion ? Palette.text : Palette.secondary).lineLimit(2)
                        }.frame(maxWidth: .infinity).frame(minHeight: 90)
                    }.buttonStyle(.plain).accessibilityIdentifier("emotion.\(emotion.rawValue)")
                        .accessibilityAddTraits(store.emotion == emotion ? [.isSelected] : [])
                        .contextMenu { Button("Customize label & touch") { editing = emotion } }
                }
            }.padding(.vertical, 7)
            PrimaryButton(title: store.sharing.emotions ? "Share with \(store.partnerName)" : "Keep private · manage sharing", icon: store.sharing.emotions ? "arrow.up.right" : "lock", isLoading: store.sending) {
                if store.sharing.emotions { Task { await store.shareEmotion() } }
                else { sheet = .privacy }
            }
            if let delivery = store.latestDelivery, store.sharing.emotions {
                Text(delivery).font(.system(size: 11)).foregroundStyle(Palette.secondary)
            }
            Surface {
                VStack(spacing: 0) {
                    Button { editing = store.emotion } label: { DetailRow(icon: "slider.horizontal.3", title: "Make this feeling yours", value: "Label & touch", chevron: true) }
                    Divider().overlay(Palette.line)
                    Button { sheet = .privacy } label: { DetailRow(icon: "hand.raised", title: "Sharing permissions", value: store.sharing.emotions ? "Enabled" : "Private", chevron: true) }
                    Divider().overlay(Palette.line)
                    Button { sheet = .notificationPermission } label: { DetailRow(icon: "bell", title: "Emotion notifications", chevron: true) }
                }.buttonStyle(.plain)
            }
            DemoFootnote(text: "You choose your emotion. Sensors never assign one for you. The six light colors stay consistent across both bracelets.")
        }.sheet(item: $editing) { value in
            NavigationStack { EmotionEditor(emotion: value) }.presentationDetents([.medium, .large]).preferredColorScheme(.dark).tint(Palette.text)
        }
    }
}

private struct EmotionEditor: View {
    @Environment(ConnectionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let emotion: Emotion
    @State private var label = ""
    @State private var signal: TouchSignal = .thinking
    var body: some View {
        Form {
            Section("Your words") { TextField(emotion.title, text: $label).onChange(of: label) { if label.count > 24 { label = String(label.prefix(24)) } } }
            Section("Personal haptic") {
                Picker("Touch pattern", selection: $signal) { ForEach(TouchSignal.allCases) { Text($0.title).tag($0) } }
                Button("Preview on this iPhone") { store.preview(signal) }
            }
            Section { Label("The six core colors are fixed in this demo. Hardware color customization requires firmware support.", systemImage: "info.circle").font(.footnote).foregroundStyle(Palette.secondary) }
        }.scrollContentBackground(.hidden).background(Palette.background)
            .navigationTitle("Make it yours").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let value = label.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.emotionLabels[emotion.rawValue] = value.isEmpty ? emotion.title : value
                        store.emotionPatterns[emotion.rawValue] = signal.rawValue
                        dismiss()
                    }
                }
            }.onAppear { label = store.label(for: emotion); signal = store.signal(for: emotion) }
    }
}
