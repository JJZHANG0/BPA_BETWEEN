import SwiftUI

struct ConnectView: View {
    @Environment(ConnectionStore.self) private var store
    @Binding var sheet: AppSheet?
    @State private var confirmUnpair = false
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "Your private connection", title: "Two people. One thread.", subtitle: "A space that belongs to just the two of you.")
            HStack(spacing: 18) {
                avatar(name: store.userName, subtitle: "Your bracelet", state: store.deviceState)
                ConnectionThread(connected: store.canSend)
                avatar(name: store.partnerName, subtitle: "Partner bracelet", state: store.partnerState)
            }.padding(.vertical, 18)
            Surface {
                VStack(spacing: 7) {
                    HStack { Text(store.canSend ? "Closer, wherever you are." : "Let’s reconnect.").font(.system(size: 18, weight: .medium)); Spacer() }
                    Text(store.canSend ? "Your demo bracelets are connected. Send a small reminder that you’re here." : "Both bracelets and the remote link need to be available to share a touch.")
                        .font(.system(size: 13)).foregroundStyle(Palette.secondary).lineSpacing(4).frame(maxWidth: .infinity, alignment: .leading)
                    Divider().overlay(Palette.line).padding(.top, 12)
                    DetailRow(icon: "applewatch", title: "Your bracelet", value: store.deviceState.label)
                    DetailRow(icon: "person.crop.circle", title: "Your person", value: store.partnerState.label)
                    DetailRow(icon: "network", title: "Remote link", value: store.remoteAvailable ? "Demo online" : "Offline")
                }
            }
            if !store.canSend {
                PrimaryButton(title: "Reconnect demo pair", icon: "arrow.triangle.2.circlepath", isLoading: store.deviceState == .connecting || store.partnerState == .connecting) {
                    Task {
                        await store.reconnectDevice()
                        await store.connectPartner()
                    }
                }.accessibilityIdentifier("connect.reconnect")
            }
            Surface {
                VStack(spacing: 0) {
                    Button { sheet = .invite } label: { DetailRow(icon: "person.badge.plus", title: "Invite your person", chevron: true) }
                    Divider().overlay(Palette.line)
                    Button { sheet = .scanner } label: { DetailRow(icon: "qrcode.viewfinder", title: "Pair with a QR code", chevron: true) }
                    Divider().overlay(Palette.line)
                    Button { sheet = .bluetooth } label: { DetailRow(icon: "antenna.radiowaves.left.and.right", title: "Pair a bracelet", chevron: true) }
                }.buttonStyle(.plain)
            }
            VStack(spacing: 0) {
                Button { sheet = .privacy } label: { DetailRow(icon: "hand.raised", title: "What you share is up to you", chevron: true) }
                Button { sheet = .account } label: { DetailRow(icon: "person.crop.circle", title: "Account & profile", chevron: true) }
                if store.partnerBound {
                    Button { confirmUnpair = true } label: { DetailRow(icon: "link.badge.plus", title: "Unpair your person", chevron: true) }
                }
            }.buttonStyle(.plain)
            DemoFootnote(text: "Alex is an example partner. Pairing and remote delivery are simulated on this iPhone.")
        }.confirmationDialog("Unpair your person?", isPresented: $confirmUnpair, titleVisibility: .visible) {
            Button("Unpair & revoke sharing", role: .destructive) { store.disconnectPartner(unpair: true) }
        } message: { Text("All sharing permissions will be turned off. You can pair again at any time.") }
    }
    private func avatar(name: String, subtitle: String, state: LinkState) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().stroke(Palette.line, lineWidth: 1).frame(width: 78, height: 78)
                Circle().fill(Palette.surface).frame(width: 65, height: 65)
                Text(String(name.prefix(1)).uppercased()).font(.system(size: 25, weight: .light))
            }
            Text(name).font(.system(size: 15, weight: .medium)).lineLimit(1)
            StatusLabel(state: state)
        }.frame(width: 112).accessibilityElement(children: .combine)
    }
}
