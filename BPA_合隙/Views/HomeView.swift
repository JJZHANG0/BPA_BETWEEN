import SwiftUI

struct HomeView: View {
    @Environment(ConnectionStore.self) private var store
    @Binding var sheet: AppSheet?
    var body: some View {
        PageScroll {
            VStack(alignment: .leading, spacing: 12) {
                HStack { Eyebrow(text: "Made for the two of you"); Spacer(); Image(systemName: "infinity").foregroundStyle(Palette.secondary).font(.system(size: 16, weight: .light)) }
                Text("A little closer.\nEven from afar.").font(.system(size: 38, weight: .light)).tracking(-1.4).lineSpacing(1)
            }
            VStack(spacing: 0) {
                BraceletPair(emotion: store.emotion, connected: store.canSend).padding(.top, -8)
                HStack(alignment: .center) {
                    person(name: store.userName, state: store.deviceState, detail: store.label(for: store.emotion), color: store.emotion.color)
                    ConnectionThread(connected: store.canSend).frame(maxWidth: 60).padding(.horizontal, 12)
                    person(name: store.partnerName, state: store.partnerState, detail: "Your person", color: Emotion.missing.color)
                }.padding(.top, 8)
            }
            VStack(spacing: 16) {
                SectionHeading(title: "A touch says enough", detail: "QUICK TOUCH")
                HStack(spacing: 12) {
                    quickTouch(.thinking)
                    quickTouch(.love)
                }
                if let delivery = store.latestDelivery {
                    Label(delivery, systemImage: store.sending ? "arrow.up.circle" : store.history.first?.state == .failed ? "exclamationmark.circle" : "checkmark.circle")
                        .font(.system(size: 11)).foregroundStyle(Palette.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("delivery.status")
                }
            }
            Surface {
                HStack(spacing: 15) {
                    Circle().fill(store.emotion.color).frame(width: 9, height: 9)
                        .padding(13).overlay(Circle().stroke(store.emotion.color.opacity(0.22), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.label(for: store.emotion)).font(.system(size: 16, weight: .medium))
                        Text(store.sharing.emotions ? "Chosen by you · sharing enabled" : "Chosen by you · only visible to you")
                            .font(.system(size: 10)).foregroundStyle(Palette.secondary)
                    }
                    Spacer(minLength: 0)
                    Button { store.selectedTab = .emotion } label: { Image(systemName: "arrow.up.right").font(.system(size: 14)).frame(width: 32, height: 44) }
                        .accessibilityLabel("Change your emotion")
                }
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Eyebrow(text: "Your bracelet")
                    Label(store.deviceState == .connected ? "82% · demo battery" : "Not connected", systemImage: "battery.75percent")
                        .font(.system(size: 11)).foregroundStyle(Palette.secondary)
                }
                Spacer()
                Button { sheet = .history } label: {
                    VStack(alignment: .trailing, spacing: 7) {
                        Eyebrow(text: "Last moment")
                        if let last = store.history.first {
                            Text(last.date, style: .relative).font(.system(size: 11)).foregroundStyle(Palette.secondary)
                        } else { Text("Make the first move ↗").font(.system(size: 11)).foregroundStyle(Palette.secondary) }
                    }
                }.buttonStyle(.plain)
            }
            DemoFootnote()
        }
    }
    private func person(name: String, state: LinkState, detail: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Text(name.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(1.6).lineLimit(1)
                Circle().fill(state == .connected ? color : Palette.secondary).frame(width: 4, height: 4)
            }
            Text(detail).font(.system(size: 12)).foregroundStyle(Palette.secondary).lineLimit(1)
            StatusLabel(state: state)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func quickTouch(_ signal: TouchSignal) -> some View {
        Button { Task { await store.send(signal) } } label: {
            HStack(spacing: 9) {
                Image(systemName: signal.icon).font(.system(size: 17, weight: .light))
                Text(signal.title).font(.system(size: 11, weight: .medium)).lineLimit(1).minimumScaleFactor(0.85)
            }.frame(maxWidth: .infinity).frame(height: 57)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.line, lineWidth: 0.7))
        }.buttonStyle(.plain).disabled(store.sending).accessibilityIdentifier("quick.\(signal.rawValue)")
    }
}
