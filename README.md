# BETWEEN

An iPhone-first SwiftUI companion for a two-person emotional connection wearable. Open `BPA_合隙.xcodeproj`, select the `BPA_合隙` scheme, and run on an iOS 17+ simulator or iPhone.

The app uses the dedicated bundle identifier `IKOOTECH.BETWEEN` to keep it separate from other BPA projects on simulators and devices. Real-device installation requires a valid development signing profile and an available development-app slot on the iPhone.

## Experience

- Home: procedural dual-bracelet illustration, selected emotion, connection state, quick touches, and recent interaction.
- Connect: separate bracelet, partner, and remote-link states; example invitation QR; validated demo code; discovery and reconnection; unpairing.
- Insights: interactive Swift Charts for heart rate, HRV, EDA and movement, with sample day/week views and a clearly illustrative baseline. Sensor observations never assign an emotion.
- Touch: single tap, double tap, long press, four signals, an editable six-pulse pattern, phone feedback, and simulated delivery receipts.
- Emotion: six fixed colors, custom labels, pattern associations, explicit sharing, and independent notification preferences.
- Device: connection, rename, illustrative battery and sensor status, light preview, phone vibration preview, firmware availability, and help.
- Supporting flows: onboarding, local profile, account availability screens, privacy controls, history, notifications, and local data deletion.

## Simulation boundary

This repository contained only the Xcode starter template. No firmware, BLE characteristics, device protocol, account API, or messaging service was supplied. This implementation therefore makes **no BLE calls or network requests**. Alex is a fictional partner, QR codes and invitations are examples, and delivery receipts refer only to the local simulation. No actual account, camera scan, firmware update, push notification, or remote delivery is implemented. The corresponding screens state their availability clearly.

The app never collects passwords or pretends to authenticate. It does not request Bluetooth, camera, health, or notification permissions until there is an actual integration that requires them. The bracelet rendering is a concept illustration, not a verified hardware model.

Sharing starts disabled independently for emotions, heart rate, HRV, EDA and activity. Selecting an emotion does not send it. Unpairing a partner revokes all sharing. Disconnecting, clearing history, or deleting local data invalidates in-flight operations so late completions cannot restore removed records or show false success.

Names, labels, pattern settings, onboarding state and consent choices are saved in local preferences. Current emotion, sample readings and interaction history remain in memory. These preferences are for the demo only; production intimate data requires an explicit storage, encryption and retention design. Delete all local data resets the experience.

## Structure and integration

`Design/` contains the shared visual system and native bracelet illustrations. `Views/` contains screens, with no hardcoded backend or BLE details. `Models/ConnectionStore.swift` coordinates privacy, connection and delivery state. `Services/ConnectionServices.swift` defines injectable device, biometric and remote synchronization contracts and their simulation adapters.

For production integration:

1. Obtain the actual BLE service and characteristic definitions, command framing, pairing/security requirements, units, sampling behavior, gesture events and acknowledgment semantics. Implement a device adapter and sensor stream against those definitions.
2. Add the real identity provider, secure credential handling and account deletion service. Implement expiring, authenticated partner invitations and revocable two-person binding.
3. Implement authenticated remote messaging, per-category server authorization, replay protection, idempotent delivery, offline handling and end-device acknowledgments. A server receipt alone must not be shown as bracelet delivery.
4. Add platform permissions at the point of use, verified firmware updates and hardware capability checks. Validate haptic timing on the real motor; iPhone feedback only illustrates the pulse rhythm.
5. Keep the example biometric provider isolated from live readings and calculate an individual baseline only after sufficient real data. Add production privacy disclosures and retention controls before collecting personal data.

## Validation

Verified on 2026-11-25 with Xcode 27.2: all 8 state/privacy tests and all 4 UI tests passed on iPhone 18 Pro (iOS 27.2). The 8 state/privacy tests and six-section UI flow also passed on iPhone SE, 3rd generation (iOS 18.2). Simulator screenshots were inspected for layout.

The test target covers default privacy, explicit emotion sharing, disconnected sends, permission revocation, in-flight disconnection, deletion races, preference persistence and device errors. The UI target covers onboarding, all six sections, emotion selection, quick-touch receipts, privacy toggles, reconnection, single/double/long-press touch gestures, and delivery continuing after navigation, and attaches screenshots.

Run with Xcode’s Product → Test, or:

```sh
xcodebuild -project BPA_合隙.xcodeproj -scheme BPA_合隙 \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  CODE_SIGNING_ALLOWED=NO test
```

Use an available simulator name from `xcrun simctl list devices available`. UI tests use an isolated preferences suite through a Debug-only launch argument; ordinary app data is not reset by tests.
