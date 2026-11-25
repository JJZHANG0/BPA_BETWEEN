import SwiftUI

struct OnboardingView: View {
    @Environment(ConnectionStore.self) private var store
    @State private var step = 0
    @State private var showAccount = false
    private let titles = ["Feel closer.\nBeyond distance.", "A feeling.\nA color. A connection.", "Your connection.\nYour choice."]
    private let descriptions = ["Two bracelets. A quiet language of touch.\nA little of you, wherever they are.", "Six colors for the things words can’t hold.\nYou choose what your feeling means.", "Your feelings and body data stay private.\nShare only what feels right, whenever you’re ready."]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack { Text("BETWEEN").font(.system(size: 15, weight: .semibold)).tracking(5); Spacer(); Text("01 — 02").font(.system(size: 10)).tracking(2).foregroundStyle(Palette.secondary) }
                    .padding(.top, 25)
                Spacer(minLength: 10)
                BraceletPair(emotion: step == 1 ? .missing : .calm).padding(.vertical, 20)
                HStack(spacing: 6) { ForEach(0..<3) { index in Capsule().fill(step == index ? Palette.text : Palette.line).frame(width: step == index ? 24 : 6, height: 3) } }.animation(.easeInOut(duration: 0.25), value: step)
                Text(titles[step]).font(.system(size: 40, weight: .light)).tracking(-1.5).fixedSize(horizontal: false, vertical: true)
                Text(descriptions[step]).font(.system(size: 14)).foregroundStyle(Palette.secondary).lineSpacing(6)
                Spacer(minLength: 10)
                PrimaryButton(title: step < 2 ? "A little closer" : "Explore the demo", icon: "arrow.right") {
                    if step < 2 { withAnimation { step += 1 } } else { store.startDemo() }
                }.accessibilityIdentifier("onboarding.continue")
                Button { showAccount = true } label: { Text("Already have an account? Sign in").font(.system(size: 12)).foregroundStyle(Palette.secondary).frame(maxWidth: .infinity, minHeight: 44) }
                DemoFootnote(text: "Explore with an example partner and simulated bracelets. No account, Bluetooth, or personal health data required.")
            }.padding(28).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }.scrollIndicators(.hidden)
            .sheet(isPresented: $showAccount) { NavigationStack { AccountAccessView() }.preferredColorScheme(.dark).tint(Palette.text) }
    }
}

struct AccountAccessView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var registration = false
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "A space for two", title: registration ? "Begin your connection." : "Welcome back.", subtitle: registration ? "Your private connection starts with a secure account." : "Your moments, waiting for you.")
            Surface {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "lock.shield").font(.system(size: 30, weight: .ultraLight))
                    Text("Account service isn’t connected yet.").font(.system(size: 18, weight: .medium))
                    Text("This version is a local demo. Secure sign-in and registration will be available when BETWEEN’s account service is connected. No credentials are collected here.")
                        .font(.system(size: 13)).foregroundStyle(Palette.secondary).lineSpacing(5)
                }
            }
            PrimaryButton(title: "Back to the experience", icon: "arrow.right") { dismiss() }
            Button(registration ? "Have an account? Sign in" : "New to BETWEEN? Create an account") { registration.toggle() }
                .font(.system(size: 13)).frame(maxWidth: .infinity, minHeight: 44)
        }.navigationTitle(registration ? "Create account" : "Sign in").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
    }
}
