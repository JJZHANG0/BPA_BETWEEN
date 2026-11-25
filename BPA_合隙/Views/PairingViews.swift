import SwiftUI
import CoreImage.CIFilterBuiltins

struct InvitationView: View {
    @Environment(ConnectionStore.self) private var store
    @State private var copied = false
    private let code = "BETWEEN-DEMO"
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "Better with your person", title: "This space is for you.\nAnd them.", subtitle: "In the full experience, your private invitation brings two bracelets together.")
            VStack(spacing: 20) {
                if let image = qrImage {
                    Image(uiImage: image).interpolation(.none).resizable().scaledToFit().frame(width: 174, height: 174)
                        .padding(20).background(Palette.text, in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel("Example pairing QR code. Demo only.")
                }
                Text("EXAMPLE INVITATION").font(.system(size: 9)).tracking(2).foregroundStyle(Palette.secondary)
                Text(code).font(.system(size: 16, weight: .medium, design: .monospaced)).tracking(2)
            }.frame(maxWidth: .infinity).padding(.vertical, 10)
            PrimaryButton(title: copied ? "Demo code copied" : "Copy demo code", icon: copied ? "checkmark" : "doc.on.doc") {
                UIPasteboard.general.string = code
                copied = true
            }
            NavigationLink { PairingCodeView() } label: { DetailRow(icon: "qrcode.viewfinder", title: "Try the pairing experience", chevron: true) }
            DemoFootnote(text: "This QR code is an example, not a live invitation. It cannot connect another account. No invitation is sent to anyone.")
        }
    }
    private var qrImage: UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(code.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)), let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct PairingCodeView: View {
    @Environment(ConnectionStore.self) private var store
    @State private var code = ""
    @State private var error: String?
    @State private var paired = false
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "A private invitation", title: "Find your person.", subtitle: "Enter the example code to explore pairing.")
            ZStack {
                RoundedRectangle(cornerRadius: 22).stroke(Palette.line, style: StrokeStyle(lineWidth: 1, dash: [8, 6])).frame(width: 220, height: 220)
                VStack(spacing: 15) {
                    Image(systemName: paired ? "checkmark.circle" : "qrcode.viewfinder").font(.system(size: 58, weight: .ultraLight))
                    Text(paired ? "Demo pair connected" : "QR SCANNER PREVIEW").font(.system(size: 10)).tracking(1.3).foregroundStyle(Palette.secondary)
                }
            }.frame(maxWidth: .infinity).padding(.vertical, 10)
            Surface {
                TextField("Invitation code", text: $code).font(.system(size: 17, design: .monospaced)).textInputAutocapitalization(.characters).autocorrectionDisabled()
                    .onChange(of: code) { error = nil; paired = false }
                    .accessibilityIdentifier("pairing.code")
            }
            if let error { Label(error, systemImage: "exclamationmark.circle").font(.system(size: 12)).foregroundStyle(Emotion.frustrated.color) }
            PrimaryButton(title: paired ? "Connected to demo Alex" : "Connect with code", icon: paired ? "checkmark" : "arrow.right", isLoading: store.partnerState == .connecting) {
                guard code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "BETWEEN-DEMO" else {
                    error = "That code isn’t recognized. Try BETWEEN-DEMO."
                    return
                }
                Task { await store.connectPartner(); paired = store.partnerState == .connected }
            }
            Button("Use example code") { code = "BETWEEN-DEMO" }.font(.system(size: 13)).frame(maxWidth: .infinity, minHeight: 44)
            DemoFootnote(text: "Camera scanning and real invitations are unavailable in this demo. No camera permission is requested. The example code connects only to the simulated partner.")
        }.navigationTitle("Pair with a code").navigationBarTitleDisplayMode(.inline)
    }
}

struct BraceletPairingView: View {
    @Environment(ConnectionStore.self) private var store
    @State private var discovered = false
    @State private var searching = false
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "One small connection", title: "Meet your bracelet.", subtitle: "In the full experience, Bluetooth connects your bracelet securely to this iPhone.")
            BraceletView(lit: discovered).frame(maxWidth: .infinity).frame(height: 260)
            if searching {
                Surface {
                    HStack(spacing: 16) {
                        ProgressView()
                        VStack(alignment: .leading, spacing: 9) {
                            RoundedRectangle(cornerRadius: 3).fill(Palette.raised).frame(width: 130, height: 12)
                            Text("Finding an example bracelet…").font(.system(size: 11)).foregroundStyle(Palette.secondary)
                        }
                    }
                }
            } else if discovered {
                Surface {
                    HStack {
                        Image(systemName: "applewatch").font(.system(size: 25, weight: .light))
                        VStack(alignment: .leading, spacing: 7) { Text(store.deviceName).font(.system(size: 16)); Text("Example bracelet · nearby in demo").font(.system(size: 11)).foregroundStyle(Palette.secondary) }
                        Spacer()
                        Image(systemName: "checkmark.circle").foregroundStyle(Emotion.safe.color)
                    }
                }
                PrimaryButton(title: store.deviceState == .connected ? "Demo bracelet connected" : "Pair demo bracelet", icon: "checkmark", isLoading: store.deviceState == .connecting) { Task { await store.reconnectDevice() } }
            } else {
                PrimaryButton(title: "Find a demo bracelet", icon: "antenna.radiowaves.left.and.right") {
                    searching = true
                    Task { try? await Task.sleep(for: .milliseconds(900)); searching = false; discovered = true }
                }
            }
            DemoFootnote(text: "Bluetooth access is not requested in demo mode. Real pairing will request permission after verified hardware support is connected. No nearby devices are scanned.")
        }
    }
}
