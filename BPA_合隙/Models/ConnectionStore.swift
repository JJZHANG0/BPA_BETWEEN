import Foundation
import Observation

@MainActor
@Observable
final class ConnectionStore {
    var selectedTab: AppTab = .home
    var onboardingComplete: Bool { didSet { defaults.set(onboardingComplete, forKey: "between.onboarded") } }
    var userName: String { didSet { defaults.set(userName, forKey: "between.name") } }
    var deviceName: String { didSet { defaults.set(deviceName, forKey: "between.deviceName") } }
    var emotion: Emotion = .calm
    var emotionLabels: [String: String] { didSet { defaults.set(emotionLabels, forKey: "between.labels") } }
    var emotionPatterns: [String: String] { didSet { defaults.set(emotionPatterns, forKey: "between.emotionPatterns") } }
    var sharing: SharingPreferences { didSet { persistPreferences() } }
    var customPattern: [Double] { didSet { defaults.set(customPattern, forKey: "between.pattern") } }
    var deviceState: LinkState = .connected
    var partnerState: LinkState = .connected
    var remoteAvailable = true
    var partnerName = "Alex"
    var history: [Interaction] = []
    var sending = false
    var notice: String?
    var ledPreview: Emotion?
    var latestDelivery: String?
    var deviceBound = true
    var partnerBound = true
    var notificationsRead = false
    let biometrics: any BiometricProviding
    private let device: any DeviceCommunicating
    private let remote: any RemoteSynchronizing
    private let defaults: UserDefaults
    private let haptics = HapticPreview()
    private var generation = 0

    init(defaults: UserDefaults = .standard,
         device: (any DeviceCommunicating)? = nil,
         remote: (any RemoteSynchronizing)? = nil,
         biometrics: (any BiometricProviding)? = nil) {
        self.defaults = defaults
        self.device = device ?? SimulatedDeviceService()
        self.remote = remote ?? SimulatedRemoteService()
        self.biometrics = biometrics ?? SampleBiometricService()
        onboardingComplete = defaults.bool(forKey: "between.onboarded")
        userName = defaults.string(forKey: "between.name") ?? "You"
        deviceName = defaults.string(forKey: "between.deviceName") ?? "BETWEEN 01"
        emotionLabels = defaults.dictionary(forKey: "between.labels") as? [String: String] ?? [:]
        emotionPatterns = defaults.dictionary(forKey: "between.emotionPatterns") as? [String: String] ?? [:]
        customPattern = defaults.array(forKey: "between.pattern") as? [Double] ?? [0.18, 0.45, 0.18]
        if let data = defaults.data(forKey: "between.privacy"), let value = try? JSONDecoder().decode(SharingPreferences.self, from: data) {
            sharing = value
        } else { sharing = SharingPreferences() }
    }

    var canSend: Bool { deviceBound && partnerBound && deviceState == .connected && partnerState == .connected && remoteAvailable }
    var unreadCount: Int { notificationsRead ? 0 : history.filter { $0.state == .delivered }.count }
    func label(for emotion: Emotion) -> String { emotionLabels[emotion.rawValue] ?? emotion.title }
    func pattern(for signal: TouchSignal) -> [Double] { signal == .custom ? customPattern : signal.pattern }
    func signal(for emotion: Emotion) -> TouchSignal { TouchSignal(rawValue: emotionPatterns[emotion.rawValue] ?? "thinking") ?? .thinking }
    func preview(_ signal: TouchSignal) { haptics.play(pattern(for: signal)) }

    func selectEmotion(_ value: Emotion) {
        emotion = value
        haptics.play(pattern(for: signal(for: value)))
    }

    func send(_ signal: TouchSignal) async { await transmit(title: signal.title, icon: signal.icon) }
    func shareEmotion() async {
        guard sharing.emotions else { notice = "Enable emotion sharing in Privacy before sharing your feeling."; return }
        await transmit(title: label(for: emotion), icon: "circle.hexagongrid", sharingEmotion: true)
    }
    private func transmit(title: String, icon: String, sharingEmotion: Bool = false) async {
        guard !sending else { return }
        guard canSend else { notice = "Reconnect both bracelets and the remote link before sending a touch."; return }
        let token = generation
        let id = UUID()
        sending = true
        latestDelivery = "Sending in demo…"
        history.insert(Interaction(id: id, title: title, icon: icon, date: Date(), state: .sending), at: 0)
        do {
            try await remote.deliver(title: title)
            guard token == generation else { return }
            guard canSend, !sharingEmotion || sharing.emotions else { throw CancellationError() }
            updateInteraction(id, state: .delivered)
            notificationsRead = false
            latestDelivery = "Delivered in demo · no physical bracelet contacted"
        } catch {
            guard token == generation else { return }
            updateInteraction(id, state: .failed)
            latestDelivery = "Not delivered. Check your connection and try again."
        }
        sending = false
    }
    private func updateInteraction(_ id: UUID, state: DeliveryState) {
        if let index = history.firstIndex(where: { $0.id == id }) { history[index].state = state }
    }
    private func invalidatePending() {
        generation += 1
        if deviceState == .connecting { deviceState = .disconnected }
        if partnerState == .connecting { partnerState = .disconnected }
        for index in history.indices where history[index].state == .sending { history[index].state = .failed }
        sending = false
        latestDelivery = nil
        haptics.stop()
    }
    func reconnectDevice() async {
        guard deviceState != .connecting else { return }
        deviceState = .connecting
        let token = generation
        do {
            try await device.connect()
            guard token == generation else { return }
            deviceBound = true
            deviceState = .connected
        } catch {
            guard token == generation else { return }
            deviceState = .failed
        }
    }
    func connectPartner() async {
        guard partnerState != .connecting else { return }
        partnerState = .connecting
        let token = generation
        do {
            try await remote.deliver(title: "Demo pairing")
            guard token == generation else { return }
            partnerBound = true
            partnerState = .connected
            remoteAvailable = true
        } catch {
            guard token == generation else { return }
            partnerState = .failed
        }
    }
    func disconnectDevice(unpair: Bool = false) {
        invalidatePending()
        deviceState = .disconnected
        if unpair { deviceBound = false }
    }
    func disconnectPartner(unpair: Bool = false) {
        invalidatePending()
        partnerState = .disconnected
        if unpair {
            partnerBound = false
            revokeSharing()
        }
    }
    func revokeSharing() {
        sharing.emotions = false
        sharing.heartRate = false
        sharing.hrv = false
        sharing.eda = false
        sharing.activity = false
    }
    func testLED(_ value: Emotion) async {
        guard deviceState == .connected else { notice = "Connect your demo bracelet to preview its light."; return }
        let token = generation
        do {
            try await device.previewLED(value)
            guard token == generation else { return }
            ledPreview = value
        } catch { notice = "The light preview couldn’t start. Please reconnect and try again." }
    }
    func testMotor() async {
        guard deviceState == .connected else { notice = "Connect your demo bracelet to preview a vibration."; return }
        do {
            try await device.previewVibration(customPattern)
            guard deviceState == .connected else { return }
            haptics.play(customPattern)
            notice = "Phone preview played. A physical bracelet has not been contacted."
        } catch { notice = "The vibration preview couldn’t start. Please try again." }
    }
    func clearHistory() { invalidatePending(); history.removeAll(); notificationsRead = true }
    func reset() {
        invalidatePending()
        history.removeAll()
        sharing = SharingPreferences()
        userName = "You"
        deviceName = "BETWEEN 01"
        emotionLabels = [:]
        emotionPatterns = [:]
        customPattern = [0.18, 0.45, 0.18]
        emotion = .calm
        ledPreview = nil
        deviceBound = false
        partnerBound = false
        deviceState = .disconnected
        partnerState = .disconnected
        selectedTab = .home
        onboardingComplete = false
    }
    func startDemo() {
        deviceBound = true
        partnerBound = true
        deviceState = .connected
        partnerState = .connected
        remoteAvailable = true
        onboardingComplete = true
    }
    private func persistPreferences() {
        if let data = try? JSONEncoder().encode(sharing) { defaults.set(data, forKey: "between.privacy") }
    }
}
