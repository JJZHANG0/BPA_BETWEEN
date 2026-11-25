import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255, opacity: 1)
    }
}

enum Palette {
    static let background = Color(hex: 0x17191D)
    static let surface = Color(hex: 0x22252A)
    static let raised = Color(hex: 0x2A2D32)
    static let text = Color(hex: 0xF5F5F2)
    static let secondary = Color(hex: 0xA5A9B0)
    static let line = Color.white.opacity(0.10)
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(2.2).foregroundStyle(Palette.secondary)
    }
}

struct PageHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: eyebrow)
            Text(title).font(.system(size: 35, weight: .light)).tracking(-1.2).foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle).font(.system(size: 14)).foregroundStyle(Palette.secondary).lineSpacing(4)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionHeading: View {
    let title: String
    var detail: String? = nil
    var body: some View {
        HStack {
            Text(title).font(.system(size: 17, weight: .medium))
            Spacer()
            if let detail { Text(detail).font(.system(size: 11)).foregroundStyle(Palette.secondary) }
        }
    }
}

struct Surface<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.line, lineWidth: 0.7))
    }
}

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if isLoading { ProgressView().tint(Palette.background) }
                Text(title).font(.system(size: 14, weight: .semibold))
                if let icon, !isLoading { Image(systemName: icon).font(.system(size: 12, weight: .semibold)) }
            }.frame(maxWidth: .infinity).frame(minHeight: 52)
        }.buttonStyle(PressStyle()).disabled(isLoading)
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(Palette.background)
            .background(Palette.text.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 13))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var chevron = false
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 17, weight: .light)).foregroundStyle(Palette.secondary).frame(width: 24)
            Text(title).font(.system(size: 14))
            Spacer(minLength: 8)
            if let value { Text(value).font(.system(size: 12)).foregroundStyle(Palette.secondary).multilineTextAlignment(.trailing) }
            if chevron { Image(systemName: "chevron.right").font(.system(size: 10, weight: .medium)).foregroundStyle(Palette.secondary) }
        }.padding(.vertical, 10).frame(minHeight: 44).contentShape(Rectangle())
    }
}

struct StatusLabel: View {
    let state: LinkState
    var body: some View {
        HStack(spacing: 6) {
            if state == .connecting { ProgressView().scaleEffect(0.65).frame(width: 8, height: 8) }
            else { Circle().fill(state == .connected ? Emotion.safe.color : Palette.secondary).frame(width: 5, height: 5) }
            Text(state.label).font(.system(size: 11))
        }.foregroundStyle(Palette.secondary)
    }
}

struct DemoFootnote: View {
    var text = "Demo experience · no physical bracelets connected"
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle").padding(.top, 1)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }.font(.system(size: 11)).foregroundStyle(Palette.secondary).lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PageScroll<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) { content }
                .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 28)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
        }.scrollIndicators(.hidden).background(Palette.background)
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 32, weight: .ultraLight)).foregroundStyle(Palette.secondary)
            Text(title).font(.system(size: 19, weight: .medium))
            Text(message).font(.system(size: 13)).foregroundStyle(Palette.secondary).multilineTextAlignment(.center).lineSpacing(4)
        }.frame(maxWidth: .infinity).padding(.vertical, 36)
    }
}
