import SwiftUI
import Charts

private enum BiometricMetric: String, CaseIterable, Identifiable {
    case heart = "Heart rate", hrv = "HRV", eda = "EDA", motion = "Activity"
    var id: String { rawValue }
    var unit: String {
        switch self { case .heart: "BPM"; case .hrv: "MS"; case .eda: "µS"; case .motion: "%" }
    }
    var icon: String {
        switch self { case .heart: "heart"; case .hrv: "waveform.path.ecg"; case .eda: "drop"; case .motion: "figure.walk" }
    }
    var domain: ClosedRange<Double> {
        switch self { case .heart: 45...95; case .hrv: 30...80; case .eda: 0...4; case .motion: 0...60 }
    }
    var baseline: Double {
        switch self { case .heart: 67; case .hrv: 56; case .eda: 1.6; case .motion: 22 }
    }
    var observation: String {
        switch self {
        case .heart: "Heart rate changes with movement, rest, and many other factors. This example shows a quieter evening rhythm."
        case .hrv: "HRV reflects variation between heartbeats. Compare with your own baseline over time, rather than someone else’s."
        case .eda: "Skin conductance can change with temperature, movement, and arousal. It cannot identify a particular emotion."
        case .motion: "Movement provides context for other signals. This example illustrates time spent in motion during each hour."
        }
    }
    func value(_ sample: SensorSample) -> Double {
        switch self { case .heart: sample.heartRate; case .hrv: sample.hrv; case .eda: sample.eda; case .motion: sample.motion }
    }
}

struct InsightsView: View {
    @Environment(ConnectionStore.self) private var store
    @State private var metric: BiometricMetric = .heart
    @State private var period = "Day"
    @State private var selectedHour: Int?
    private let periods = ["Day", "Week"]
    private var points: [SensorSample] {
        period == "Day" ? store.biometrics.samples : store.biometrics.samples.enumerated().filter { $0.offset % 3 == 0 }.prefix(7).map { $0.element }
    }
    private var selectedSample: SensorSample? {
        guard !points.isEmpty else { return nil }
        guard let selectedHour else { return points.last }
        if period == "Week" { return points[min(max(selectedHour, 0), points.count - 1)] }
        return points.first { $0.hour == selectedHour } ?? points.last
    }
    var body: some View {
        PageScroll {
            PageHeading(eyebrow: "Understand your rhythm", title: "Listen a little closer.", subtitle: "A thoughtful view of your body.\nYour feelings are always yours to define.")
            HStack {
                Label("Illustrative data", systemImage: "waveform.path").font(.system(size: 11)).foregroundStyle(Palette.secondary)
                Spacer()
                Picker("Time period", selection: $period) { ForEach(periods, id: \.self) { Text($0) } }.pickerStyle(.segmented).frame(width: 140)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(BiometricMetric.allCases) { item in
                    Button { withAnimation(.easeInOut(duration: 0.25)) { metric = item; selectedHour = nil } } label: {
                        Surface(padding: 12) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack { Image(systemName: item.icon).font(.system(size: 14, weight: .light)); Spacer(); if metric == item { Circle().fill(Palette.text).frame(width: 4, height: 4) } }
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    Text(store.biometrics.samples.last.map { formatted(item.value($0), for: item) } ?? "—").font(.system(size: 23, weight: .light)).monospacedDigit()
                                    Text(item.unit).font(.system(size: 7)).foregroundStyle(Palette.secondary)
                                }
                                Text(item.rawValue).font(.system(size: 10)).foregroundStyle(Palette.secondary).lineLimit(1).minimumScaleFactor(0.8)
                            }
                        }.overlay(RoundedRectangle(cornerRadius: 18).stroke(metric == item ? Color.white.opacity(0.45) : .clear, lineWidth: 1))
                    }.buttonStyle(.plain).accessibilityLabel("\(item.rawValue) chart").accessibilityAddTraits(metric == item ? [.isSelected] : [])
                }
            }
            VStack(alignment: .leading, spacing: 20) {
                SectionHeading(title: metric.rawValue, detail: period == "Day" ? "24 HOURS · SAMPLE" : "7 DAYS · SAMPLE")
                HStack(alignment: .firstTextBaseline) {
                    Text(selectedSample.map { formatted(metric.value($0), for: metric) } ?? "—").font(.system(size: 35, weight: .light)).monospacedDigit()
                    Text(metric.unit).font(.system(size: 11)).foregroundStyle(Palette.secondary)
                    Spacer()
                    Text(selectedHour == nil ? "Latest sample" : "Selected sample").font(.system(size: 11)).foregroundStyle(Palette.secondary)
                }
                Chart {
                    RuleMark(y: .value("Example baseline", metric.baseline))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4])).foregroundStyle(Palette.secondary.opacity(0.45))
                    ForEach(Array(points.enumerated()), id: \.element.id) { index, sample in
                        let x = period == "Day" ? sample.hour : index
                        AreaMark(x: .value("Time", x), yStart: .value("Minimum", metric.domain.lowerBound), yEnd: .value("Value", metric.value(sample)))
                            .foregroundStyle(LinearGradient(colors: [.white.opacity(0.10), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                        LineMark(x: .value("Time", x), y: .value(metric.rawValue, metric.value(sample)))
                            .lineStyle(StrokeStyle(lineWidth: 1.7)).foregroundStyle(Palette.text).interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: metric.domain)
                .chartXAxis {
                    AxisMarks(values: period == "Day" ? [0, 6, 12, 18, 23] : [0, 2, 4, 6]) { value in
                        AxisValueLabel {
                            if let number = value.as(Int.self) { Text(period == "Day" ? String(format: "%02d:00", number) : "D\(number + 1)").font(.system(size: 9)).foregroundStyle(Palette.secondary) }
                        }
                    }
                }
                .chartYAxis { AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in AxisGridLine().foregroundStyle(Palette.line); AxisValueLabel().foregroundStyle(Palette.secondary) } }
                .chartXSelection(value: $selectedHour)
                .frame(height: 170)
                HStack { Circle().fill(Palette.text).frame(width: 4, height: 4); Text("Sample readings"); Spacer(); Text("– –  Example baseline") }
                    .font(.system(size: 10)).foregroundStyle(Palette.secondary)
            }
            Surface {
                VStack(alignment: .leading, spacing: 12) {
                    Label("A signal, not a diagnosis", systemImage: "waveform.path.ecg").font(.system(size: 14, weight: .medium))
                    Text(metric.observation).font(.system(size: 12)).foregroundStyle(Palette.secondary).lineSpacing(5)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                SectionHeading(title: "Your personal baseline", detail: "PREVIEW")
                Text("A real baseline needs consistent readings from your bracelet. The dashed line above is an example, not a measurement of you.")
                    .font(.system(size: 12)).foregroundStyle(Palette.secondary).lineSpacing(5)
            }
            HStack(spacing: 10) {
                Circle().fill(store.emotion.color).frame(width: 8, height: 8)
                Text("You selected “\(store.label(for: store.emotion))”.").font(.system(size: 12))
                Spacer()
                Text("SELF-REPORTED").font(.system(size: 8)).tracking(0.7).foregroundStyle(Palette.secondary)
            }
            DemoFootnote(text: "All readings and trends are sample data. BETWEEN does not diagnose emotions or medical conditions.")
        }.onChange(of: period) { selectedHour = nil }
    }
    private func formatted(_ value: Double, for metric: BiometricMetric) -> String { metric == .eda ? String(format: "%.1f", value) : String(Int(value)) }
}
