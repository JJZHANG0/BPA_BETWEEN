import SwiftUI

struct DeviceView: View {
    @Environment(ConnectionStore.self) private var store
    @Binding var sheet: AppSheet?
    @State private var rename = false
    @State private var name = ""
    @State private var unpair = false
    @State private var checkingFirmware = false
    @State private var firmwareMessage: String?
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "Considered in every detail", title: "Your connection,\nbeautifully simple.", subtitle: "A little care for the thing that keeps you close.")
            VStack(spacing: 22) {
                BraceletView(color: (store.ledPreview ?? store.emotion).color, rotation: -28, lit: store.deviceState == .connected)
                    .frame(maxWidth: .infinity).frame(height: 240)
                    .animation(.easeInOut(duration: 0.35), value: store.ledPreview)
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.deviceName).font(.system(size: 20, weight: .light))
                        StatusLabel(state: store.deviceState)
                    }
                    Spacer()
                    if store.deviceState == .connected {
                        VStack(alignment: .trailing, spacing: 7) {
                            HStack(spacing: 6) { Image(systemName: "battery.75percent"); Text("82%").monospacedDigit() }.font(.system(size: 17, weight: .light))
                            Text("DEMO BATTERY").font(.system(size: 8)).tracking(1.3).foregroundStyle(Palette.secondary)
                        }
                    }
                }
            }
            if store.deviceState != .connected {
                PrimaryButton(title: store.deviceBound ? "Reconnect bracelet" : "Find a demo bracelet", icon: "antenna.radiowaves.left.and.right", isLoading: store.deviceState == .connecting) { Task { await store.reconnectDevice() } }
            }
            Surface {
                VStack(spacing: 0) {
                    Button { name = store.deviceName; rename = true } label: { DetailRow(icon: "pencil", title: "Device name", value: "Rename", chevron: true) }
                    Divider().overlay(Palette.line)
                    DetailRow(icon: "cpu", title: "Firmware", value: "Demo · not installed")
                    Divider().overlay(Palette.line)
                    Button {
                        checkingFirmware = true
                        Task {
                            try? await Task.sleep(for: .milliseconds(650))
                            checkingFirmware = false
                            firmwareMessage = "Firmware updates require a physical bracelet and a verified update service. No update has been downloaded or installed."
                        }
                    } label: { DetailRow(icon: "arrow.down.circle", title: checkingFirmware ? "Checking availability…" : "Firmware update", chevron: true) }.disabled(checkingFirmware)
                }.buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(title: "A light. A little reassurance.", detail: "LED PREVIEW")
                HStack {
                    ForEach(Emotion.allCases) { emotion in
                        Button { Task { await store.testLED(emotion) } } label: {
                            Circle().fill(emotion.color).frame(width: 23, height: 23).padding(9)
                                .overlay(Circle().stroke(store.ledPreview == emotion ? emotion.color : .clear, lineWidth: 1))
                        }.buttonStyle(.plain).frame(maxWidth: .infinity).accessibilityLabel("Preview \(emotion.title) light")
                    }
                }
            }
            Surface {
                VStack(spacing: 0) {
                    Button { Task { await store.testMotor() } } label: { DetailRow(icon: "waveform", title: "Preview vibration", value: "On iPhone", chevron: true) }
                    Divider().overlay(Palette.line)
                    DetailRow(icon: "waveform.path.ecg", title: "PPG · heart rate & HRV", value: store.deviceState == .connected ? "Sample feed" : "Offline")
                    Divider().overlay(Palette.line)
                    DetailRow(icon: "drop", title: "EDA · skin conductance", value: store.deviceState == .connected ? "Sample feed" : "Offline")
                    Divider().overlay(Palette.line)
                    DetailRow(icon: "figure.walk", title: "Motion sensor", value: store.deviceState == .connected ? "Sample feed" : "Offline")
                }.buttonStyle(.plain)
            }
            VStack(spacing: 0) {
                Button { sheet = .help } label: { DetailRow(icon: "questionmark.circle", title: "Device help & troubleshooting", chevron: true) }
                if store.deviceState == .connected {
                    Button { store.disconnectDevice() } label: { DetailRow(icon: "pause.circle", title: "Disconnect demo bracelet", chevron: true) }.accessibilityIdentifier("device.disconnect")
                }
                if store.deviceBound { Button { unpair = true } label: { DetailRow(icon: "minus.circle", title: "Unpair bracelet", chevron: true) } }
            }.buttonStyle(.plain)
            DemoFootnote(text: "Concept bracelet visualization. Battery, sensor status, LED and motor controls are simulated; no hardware commands are sent.")
        }
        .alert("Name your bracelet", isPresented: $rename) {
            TextField("Bracelet name", text: $name)
            Button("Cancel", role: .cancel) { }
            Button("Save") { let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines); if !trimmed.isEmpty { store.deviceName = String(trimmed.prefix(30)) } }
        }
        .alert("Firmware availability", isPresented: Binding(get: { firmwareMessage != nil }, set: { if !$0 { firmwareMessage = nil } })) {
            Button("OK") { firmwareMessage = nil }
        } message: { Text(firmwareMessage ?? "") }
        .confirmationDialog("Unpair your bracelet?", isPresented: $unpair, titleVisibility: .visible) {
            Button("Unpair bracelet", role: .destructive) { store.disconnectDevice(unpair: true) }
        } message: { Text("Touch delivery will pause until you pair a bracelet again.") }
    }
}
