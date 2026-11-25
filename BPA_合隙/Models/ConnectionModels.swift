import Foundation
import SwiftUI

enum Emotion: String, CaseIterable, Identifiable, Codable {
    case calm, safe, happy, missing, anxious, frustrated
    var id: String { rawValue }
    var title: String {
        switch self {
        case .calm: "Calm"
        case .safe: "Safe"
        case .happy: "Happy"
        case .missing: "Missing you"
        case .anxious: "Anxious"
        case .frustrated: "Frustrated"
        }
    }
    var color: Color {
        switch self {
        case .calm: Color(hex: 0x5B8DEF)
        case .safe: Color(hex: 0x63B78A)
        case .happy: Color(hex: 0xF2C75C)
        case .missing: Color(hex: 0xE98EAF)
        case .anxious: Color(hex: 0x9B83D5)
        case .frustrated: Color(hex: 0xE76D67)
        }
    }
    var message: String {
        switch self {
        case .calm: "A little stillness, shared."
        case .safe: "Right here is where I belong."
        case .happy: "Some moments feel brighter together."
        case .missing: "You’re on my mind, wherever you are."
        case .anxious: "A little reassurance goes a long way."
        case .frustrated: "A moment to pause. A space to be heard."
        }
    }
}

enum TouchSignal: String, CaseIterable, Identifiable, Codable {
    case thinking, here, goodnight, love, custom
    var id: String { rawValue }
    var title: String {
        switch self {
        case .thinking: "Thinking of you"
        case .here: "I’m here"
        case .goodnight: "Good night"
        case .love: "Sending love"
        case .custom: "Your touch"
        }
    }
    var icon: String {
        switch self {
        case .thinking: "sparkle"
        case .here: "hand.wave"
        case .goodnight: "moon"
        case .love: "heart"
        case .custom: "waveform.path"
        }
    }
    var gesture: String {
        switch self {
        case .thinking: "Single tap"
        case .here: "Double tap"
        case .goodnight: "Long press"
        case .love: "Three soft pulses"
        case .custom: "Personal pattern"
        }
    }
    var pattern: [Double] {
        switch self {
        case .thinking: [0.18]
        case .here: [0.16, 0.16]
        case .goodnight: [0.7]
        case .love: [0.16, 0.3, 0.16]
        case .custom: [0.18, 0.45, 0.18]
        }
    }
}

enum LinkState: Equatable {
    case disconnected, connecting, connected, failed
    var label: String {
        switch self {
        case .disconnected: "Not connected"
        case .connecting: "Connecting…"
        case .connected: "Connected"
        case .failed: "Connection interrupted"
        }
    }
}

enum DeliveryState: String { case sending, delivered, failed }
struct Interaction: Identifiable {
    let id: UUID
    let title: String
    let icon: String
    let date: Date
    var state: DeliveryState
}

struct SharingPreferences: Codable {
    var emotions = false
    var heartRate = false
    var hrv = false
    var eda = false
    var activity = false
    var touchNotifications = true
    var emotionNotifications = false
}

struct SensorSample: Identifiable {
    let hour: Int
    let heartRate: Double
    let hrv: Double
    let eda: Double
    let motion: Double
    var id: Int { hour }
}
