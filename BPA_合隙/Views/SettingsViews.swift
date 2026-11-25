import SwiftUI

struct SheetContent: View {
    let destination: AppSheet
    var body: some View {
        switch destination {
        case .privacy: PrivacyView()
        case .history: HistoryView(notifications: false)
        case .notifications: HistoryView(notifications: true)
        case .help: HelpView()
        case .invite: InvitationView()
        case .scanner: PairingCodeView()
        case .pattern: PatternEditor()
        case .account: ProfileView()
        case .bluetooth: BraceletPairingView()
        case .notificationPermission: NotificationPreferencesView()
        }
    }
}

struct PrivacyView: View {
    @Environment(ConnectionStore.self) private var store
    @State private var deleteHistory = false
    @State private var deleteAll = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        @Bindable var store = store
        PageScroll {
            PageHeading(eyebrow: "Private by design", title: "Close, on your terms.", subtitle: "Choose what your person can see. Each permission is independent, and you can change your mind at any time.")
            Surface {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Visible to your person")
                    permission("Selected emotions", detail: "Only feelings you choose and explicitly send.", binding: $store.sharing.emotions)
                    Divider().overlay(Palette.line)
                    permission("Heart rate", detail: "Pulse readings from your bracelet.", binding: $store.sharing.heartRate)
                    Divider().overlay(Palette.line)
                    permission("Heart rate variability", detail: "Your HRV readings and trends.", binding: $store.sharing.hrv)
                    Divider().overlay(Palette.line)
                    permission("Skin conductance", detail: "EDA readings, without emotion labels.", binding: $store.sharing.eda)
                    Divider().overlay(Palette.line)
                    permission("Motion activity", detail: "Your movement and rest patterns.", binding: $store.sharing.activity)
                }
            }
            Text("These choices are saved on this iPhone. In demo mode, no data leaves your device. Enabling a category gives permission; it does not automatically send your current emotion.")
                .font(.system(size: 12)).foregroundStyle(Palette.secondary).lineSpacing(5)
            Button { store.revokeSharing() } label: { Label("Revoke all sharing", systemImage: "hand.raised").font(.system(size: 14)).frame(maxWidth: .infinity, minHeight: 48).overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.line)) }
            VStack(spacing: 0) {
                Button { deleteHistory = true } label: { DetailRow(icon: "clock.arrow.circlepath", title: "Clear interaction history", chevron: true) }
                Button { deleteAll = true } label: { DetailRow(icon: "trash", title: "Delete all local data", chevron: true) }
            }.buttonStyle(.plain)
            DemoFootnote(text: "History and readings exist only for this session. Profile, touch patterns, labels, and permission choices are saved locally. There is no cloud account in this demo.")
        }.confirmationDialog("Clear your moments?", isPresented: $deleteHistory, titleVisibility: .visible) {
            Button("Clear history", role: .destructive) { store.clearHistory() }
        } message: { Text("All interaction records from this session will be removed.") }
        .confirmationDialog("Delete all local data?", isPresented: $deleteAll, titleVisibility: .visible) {
            Button("Delete all local data", role: .destructive) { store.reset(); dismiss() }
        } message: { Text("This resets your profile, sharing preferences, labels, patterns and history, then returns to the welcome screen.") }
    }
    private func permission(_ title: String, detail: String, binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 14))
                Text(detail).font(.system(size: 11)).foregroundStyle(Palette.secondary).lineSpacing(3)
            }.padding(.vertical, 9)
        }.tint(Emotion.safe.color).accessibilityIdentifier("privacy.\(title)")
    }
}

struct NotificationPreferencesView: View {
    @Environment(ConnectionStore.self) private var store
    var body: some View {
        @Bindable var store = store
        PageScroll {
            PageHeading(eyebrow: "Gentle reminders", title: "Let a little love in.", subtitle: "Choose the moments you’d like to hear about.")
            Surface {
                VStack(spacing: 22) {
                    Toggle("Touch notifications", isOn: $store.sharing.touchNotifications)
                    Divider().overlay(Palette.line)
                    Toggle("Emotion notifications", isOn: $store.sharing.emotionNotifications)
                }.font(.system(size: 14)).tint(Emotion.safe.color)
            }
            DemoFootnote(text: "These are saved preferences for future partner notifications. This demo does not request system notification access or send push notifications. Delivery receipts remain available in Your moments.")
        }
    }
}

struct ProfileView: View {
    @Environment(ConnectionStore.self) private var store
    @State private var name = ""
    @State private var saved = false
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "The person behind the touch", title: "Make yourself at home.", subtitle: "A local profile, just for this experience.")
            Surface {
                VStack(alignment: .leading, spacing: 14) {
                    Eyebrow(text: "Your name")
                    TextField("What should we call you?", text: $name).font(.system(size: 22, weight: .light)).textContentType(.nickname)
                        .onChange(of: name) { saved = false; if name.count > 24 { name = String(name.prefix(24)) } }
                }
            }
            PrimaryButton(title: saved ? "Saved on this iPhone" : "Save profile", icon: saved ? "checkmark" : nil) {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                store.userName = trimmed.isEmpty ? "You" : trimmed
                saved = true
            }
            NavigationLink { AccountAccessView() } label: { DetailRow(icon: "person.crop.circle", title: "Sign in or create an account", chevron: true) }
            NavigationLink { PrivacyView() } label: { DetailRow(icon: "lock", title: "Privacy & data deletion", chevron: true) }
            DemoFootnote(text: "This local profile is not an authenticated account. Pairing with a real partner will require the secure account service.")
        }.onAppear { name = store.userName }
    }
}

struct HistoryView: View {
    @Environment(ConnectionStore.self) private var store
    let notifications: Bool
    @State private var clear = false
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: notifications ? "Little reminders" : "A language of your own", title: notifications ? "A moment for you." : "Small touches.\nLasting feelings.", subtitle: notifications ? "Your demo delivery receipts, all in one place." : "The quiet ways you’ve reached out this session.")
            if store.history.isEmpty {
                EmptyState(icon: notifications ? "bell" : "hand.tap", title: notifications ? "A little quiet, for now." : "Your first moment awaits.", message: "Send a touch to your demo partner.\nYour connection starts with something small.")
            } else {
                VStack(spacing: 0) {
                    ForEach(store.history) { item in
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: item.icon).font(.system(size: 19, weight: .light)).frame(width: 24).padding(.top, 3)
                            VStack(alignment: .leading, spacing: 7) {
                                Text(item.title).font(.system(size: 15))
                                Text(item.state == .delivered ? "Delivered in demo" : item.state == .sending ? "Sending in demo…" : "Not delivered")
                                    .font(.system(size: 11)).foregroundStyle(Palette.secondary)
                            }
                            Spacer()
                            Text(item.date, style: .time).font(.system(size: 11)).foregroundStyle(Palette.secondary)
                        }.padding(.vertical, 19)
                        Divider().overlay(Palette.line)
                    }
                }
                Button("Clear history", role: .destructive) { clear = true }.font(.system(size: 13)).frame(minHeight: 44)
            }
            if notifications {
                NavigationLink { NotificationPreferencesView() } label: { DetailRow(icon: "slider.horizontal.3", title: "Notification preferences", chevron: true) }
            }
            DemoFootnote(text: "These are simulated delivery receipts, not acknowledgments from a physical bracelet or another person.")
        }.onAppear { if notifications { store.notificationsRead = true } }
            .confirmationDialog("Clear all interaction history?", isPresented: $clear, titleVisibility: .visible) { Button("Clear history", role: .destructive) { store.clearHistory() } }
    }
}

struct HelpView: View {
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "A little guidance", title: "We’re right here.", subtitle: "A few thoughtful answers to keep you connected.")
            ForEach(Array(answers.enumerated()), id: \.offset) { _, item in
                Surface {
                    DisclosureGroup {
                        Text(item.1).font(.system(size: 13)).foregroundStyle(Palette.secondary).lineSpacing(5).padding(.top, 15).frame(maxWidth: .infinity, alignment: .leading)
                    } label: { Text(item.0).font(.system(size: 14, weight: .medium)) }
                }
            }
            DemoFootnote(text: "BETWEEN · Companion app preview. Real-device setup and support channels will be available with the hardware integration.")
        }
    }
    private let answers = [
        ("Why can’t I see my real bracelet?", "This version uses simulated bracelets. Real discovery needs the manufacturer’s BLE services, characteristic definitions, pairing protocol and firmware. No nearby devices are scanned in demo mode."),
        ("My demo bracelet is disconnected", "Open Device and choose Reconnect bracelet. If you unpaired it, choose Find a demo bracelet. Then check Connect to make sure your person and the remote link are connected."),
        ("A touch wasn’t delivered", "Both bracelets and the remote link need to be connected. Reconnect from Connect, then send your touch again. Failed touches are not resent automatically."),
        ("Can BETWEEN tell how I feel?", "No. Physiological signals can have many causes. You choose your own emotion; the example charts are separate from self-reported feelings."),
        ("Who can see my information?", "Sharing is off by default for every data category. You can opt in independently in Privacy & sharing, revoke permissions, or delete local data at any time. This demo does not upload data."),
        ("Why can’t I feel the phone preview?", "Phone vibration depends on device support and system settings. The iOS Simulator does not provide physical haptics. A phone preview illustrates rhythm, not the exact feel of a bracelet.")
    ]
}
