import Foundation
import UIKit

// Production adapters must implement these contracts using verified firmware and APIs.
// No UUIDs, endpoint URLs, or hardware capabilities are assumed here.
@MainActor
protocol DeviceCommunicating {
    func connect() async throws
    func previewLED(_ emotion: Emotion) async throws
    func previewVibration(_ pattern: [Double]) async throws
}

@MainActor
protocol RemoteSynchronizing {
    func deliver(title: String) async throws
}

@MainActor
protocol BiometricProviding {
    var samples: [SensorSample] { get }
}

struct SimulatedDeviceService: DeviceCommunicating {
    func connect() async throws { try await Task.sleep(for: .milliseconds(900)) }
    func previewLED(_ emotion: Emotion) async throws { try await Task.sleep(for: .milliseconds(350)) }
    func previewVibration(_ pattern: [Double]) async throws { try await Task.sleep(for: .milliseconds(350)) }
}

struct SimulatedRemoteService: RemoteSynchronizing {
    func deliver(title: String) async throws { try await Task.sleep(for: .milliseconds(1100)) }
}

struct SampleBiometricService: BiometricProviding {
    // Fixed, illustrative values. Never derived from a person or used to infer emotions.
    let samples: [SensorSample] = (0..<24).map { hour in
        let heart: [Double] = [61, 59, 58, 60, 59, 62, 66, 71, 75, 72, 69, 72, 76, 73, 70, 68, 72, 74, 71, 68, 66, 64, 63, 61]
        let variability: [Double] = [58, 61, 64, 60, 62, 58, 54, 49, 46, 51, 56, 52, 48, 50, 55, 59, 54, 51, 56, 60, 61, 63, 62, 64]
        return SensorSample(hour: hour, heartRate: heart[hour], hrv: variability[hour], eda: 1.2 + Double((hour * 7) % 10) / 10, motion: Double((hour * 13) % 45))
    }
}

@MainActor
final class HapticPreview {
    private var task: Task<Void, Never>?
    func play(_ pattern: [Double]) {
        task?.cancel()
        task = Task {
            for duration in pattern {
                guard !Task.isCancelled else { return }
                UIImpactFeedbackGenerator(style: duration > 0.35 ? .medium : .soft).impactOccurred()
                try? await Task.sleep(for: .seconds(duration + 0.18))
            }
        }
    }
    func stop() { task?.cancel() }
}
