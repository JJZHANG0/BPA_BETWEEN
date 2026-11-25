import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, connect, insights, touch, emotion, device
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .home: "square.grid.2x2"
        case .connect: "point.3.connected.trianglepath.dotted"
        case .insights: "waveform.path.ecg"
        case .touch: "hand.tap"
        case .emotion: "circle.hexagongrid"
        case .device: "applewatch"
        }
    }
}

enum AppSheet: String, Identifiable {
    case privacy, history, notifications, help, invite, scanner, pattern, account, bluetooth, notificationPermission
    var id: String { rawValue }
    var title: String {
        switch self {
        case .privacy: "Privacy & sharing"
        case .history: "Your moments"
        case .notifications: "Notifications"
        case .help: "Help & support"
        case .invite: "Invite your person"
        case .scanner: "Pair with a code"
        case .pattern: "Create a touch"
        case .account: "Your profile"
        case .bluetooth: "Bracelet connection"
        case .notificationPermission: "Stay in the moment"
        }
    }
}

struct ContentView: View {
    @Environment(ConnectionStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sheet: AppSheet?
    var body: some View {
        @Bindable var store = store
        ZStack {
            Palette.background.ignoresSafeArea()
            if store.onboardingComplete {
                VStack(spacing: 0) {
                    header
                    Group {
                        switch store.selectedTab {
                        case .home: HomeView(sheet: $sheet)
                        case .connect: ConnectView(sheet: $sheet)
                        case .insights: InsightsView()
                        case .touch: TouchView(sheet: $sheet)
                        case .emotion: EmotionView(sheet: $sheet)
                        case .device: DeviceView(sheet: $sheet)
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id(store.selectedTab)
                        .transition(.opacity)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: store.selectedTab)
                    navigation
                }
            } else { OnboardingView() }
        }
        .foregroundStyle(Palette.text).tint(Palette.text)
        .sheet(item: $sheet) { destination in
            NavigationStack {
                SheetContent(destination: destination)
                    .navigationTitle(destination.title).navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) { Button("Done") { sheet = nil }.font(.system(size: 14)) }
                    }
                    .toolbarBackground(Palette.background, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            }.presentationDragIndicator(.visible).preferredColorScheme(.dark).tint(Palette.text)
        }
        .alert("BETWEEN", isPresented: Binding(get: { store.notice != nil }, set: { if !$0 { store.notice = nil } })) {
            Button("OK") { store.notice = nil }
        } message: { Text(store.notice ?? "") }
    }
    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                Capsule().stroke(Palette.text, lineWidth: 1.4).frame(width: 8, height: 17).rotationEffect(.degrees(28))
                Capsule().stroke(Palette.text, lineWidth: 1.4).frame(width: 8, height: 17).rotationEffect(.degrees(28))
            }.accessibilityHidden(true)
            Text("BETWEEN").font(.system(size: 14, weight: .semibold)).tracking(4)
            Spacer()
            Text("DEMO").font(.system(size: 8, weight: .medium)).tracking(1.5).foregroundStyle(Palette.secondary)
                .padding(.horizontal, 7).padding(.vertical, 5).overlay(Capsule().stroke(Palette.line))
            Button { sheet = .notifications } label: {
                Image(systemName: store.unreadCount > 0 ? "bell.badge" : "bell").font(.system(size: 18, weight: .light)).frame(width: 44, height: 44)
            }.accessibilityLabel("Notifications")
        }.padding(.leading, 24).padding(.trailing, 12).padding(.vertical, 3)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.line).frame(height: 0.5) }
    }
    private var navigation: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button { store.selectedTab = tab } label: {
                    VStack(spacing: 7) {
                        Image(systemName: tab.icon).font(.system(size: 19, weight: store.selectedTab == tab ? .medium : .light)).frame(height: 22)
                        Text(tab.title).font(.system(size: 9, weight: store.selectedTab == tab ? .semibold : .regular))
                    }.foregroundStyle(store.selectedTab == tab ? Palette.text : Palette.secondary.opacity(0.7))
                        .frame(maxWidth: .infinity).padding(.top, 17).padding(.bottom, 10)
                        .overlay(alignment: .top) { if store.selectedTab == tab { Capsule().fill(Palette.text).frame(width: 17, height: 2) } }
                }.buttonStyle(.plain).accessibilityIdentifier("tab.\(tab.rawValue)")
                    .accessibilityAddTraits(store.selectedTab == tab ? [.isSelected] : [])
            }
        }.padding(.horizontal, 12).background(Palette.background)
            .overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: 0.5) }
    }
}

#Preview { ContentView().environment(ConnectionStore()) }
