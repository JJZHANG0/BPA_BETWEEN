import Foundation
import Testing
@testable import BPA_合隙

@MainActor
private struct ImmediateRemote: RemoteSynchronizing {
    func deliver(title: String) async throws { }
}

@MainActor
private final class PausedRemote: RemoteSynchronizing {
    var continuation: CheckedContinuation<Void, Error>?
    func deliver(title: String) async throws {
        try await withCheckedThrowingContinuation { continuation = $0 }
    }
    func finish() { continuation?.resume(); continuation = nil }
}

@MainActor
private struct FailingDevice: DeviceCommunicating {
    struct Unavailable: Error { }
    func connect() async throws { throw Unavailable() }
    func previewLED(_ emotion: Emotion) async throws { throw Unavailable() }
    func previewVibration(_ pattern: [Double]) async throws { throw Unavailable() }
}

@Suite("Connection and privacy")
@MainActor
struct BetweenTests {
    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: "between.tests.\(UUID().uuidString)")!
    }

    @Test func sharingStartsPrivateAndSelectionDoesNotSend() async {
        let store = ConnectionStore(defaults: defaults(), remote: ImmediateRemote())
        #expect(!store.sharing.emotions && !store.sharing.heartRate && !store.sharing.hrv && !store.sharing.eda && !store.sharing.activity)
        store.selectEmotion(.missing)
        #expect(store.emotion == .missing)
        #expect(store.history.isEmpty)
        await store.shareEmotion()
        #expect(store.history.isEmpty)
        #expect(store.notice != nil)
    }

    @Test func touchDeliveryAndDisconnectedGuard() async {
        let store = ConnectionStore(defaults: defaults(), remote: ImmediateRemote())
        await store.send(.thinking)
        #expect(store.history.count == 1)
        #expect(store.history.first?.state == .delivered)
        store.disconnectDevice()
        await store.send(.love)
        #expect(store.history.count == 1)
        #expect(!store.canSend)
    }

    @Test func unpairRevokesAllPermissions() {
        let store = ConnectionStore(defaults: defaults())
        store.sharing.emotions = true
        store.sharing.heartRate = true
        store.sharing.hrv = true
        store.sharing.eda = true
        store.sharing.activity = true
        store.disconnectPartner(unpair: true)
        #expect(!store.partnerBound)
        #expect(!store.sharing.emotions && !store.sharing.heartRate && !store.sharing.hrv && !store.sharing.eda && !store.sharing.activity)
    }

    @Test func disconnectDuringDeliveryCannotConfirmSuccess() async {
        let remote = PausedRemote()
        let store = ConnectionStore(defaults: defaults(), remote: remote)
        let delivery = Task { await store.send(.love) }
        while remote.continuation == nil { await Task.yield() }
        store.disconnectPartner()
        remote.finish()
        await delivery.value
        #expect(store.history.first?.state == .failed)
        #expect(!store.sending)
        #expect(store.latestDelivery == nil)
    }

    @Test func privacyRevocationBlocksPendingEmotion() async {
        let remote = PausedRemote()
        let store = ConnectionStore(defaults: defaults(), remote: remote)
        store.sharing.emotions = true
        let delivery = Task { await store.shareEmotion() }
        while remote.continuation == nil { await Task.yield() }
        store.revokeSharing()
        remote.finish()
        await delivery.value
        #expect(store.history.first?.state == .failed)
    }

    @Test func deletionPreventsPendingDeliveryFromReappearing() async {
        let remote = PausedRemote()
        let store = ConnectionStore(defaults: defaults(), remote: remote)
        let delivery = Task { await store.send(.here) }
        while remote.continuation == nil { await Task.yield() }
        store.reset()
        remote.finish()
        await delivery.value
        #expect(store.history.isEmpty)
        #expect(!store.onboardingComplete)
        #expect(!store.sending)
        #expect(store.latestDelivery == nil)
    }

    @Test func preferencesPersistAndResetClearsThem() {
        let preferences = defaults()
        let store = ConnectionStore(defaults: preferences)
        store.sharing.hrv = true
        store.userName = "Jamie"
        store.customPattern = [0.1, 0.7]
        store.emotionLabels[Emotion.calm.rawValue] = "At ease"
        let restored = ConnectionStore(defaults: preferences)
        #expect(restored.sharing.hrv)
        #expect(!restored.sharing.heartRate)
        #expect(restored.userName == "Jamie")
        #expect(restored.customPattern == [0.1, 0.7])
        #expect(restored.label(for: .calm) == "At ease")
        restored.reset()
        let cleared = ConnectionStore(defaults: preferences)
        #expect(!cleared.sharing.hrv)
        #expect(cleared.userName == "You")
        #expect(cleared.emotionLabels.isEmpty)
    }

    @Test func deviceFailureHasRecoverableState() async {
        let store = ConnectionStore(defaults: defaults(), device: FailingDevice())
        await store.reconnectDevice()
        #expect(store.deviceState == .failed)
        #expect(!store.canSend)
    }
}
