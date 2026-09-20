import WidgetKit
import SwiftUI

/// Осложнения в том же LCD-стиле. Смысл: даже если пользуешься штатным
/// циферблатом Apple, куски GX-ULTRA можно вынести на него — и они живые.

struct FaceEntry: TimelineEntry {
    let date: Date
    let snapshot: FaceSnapshot
}

struct FaceProvider: TimelineProvider {
    func placeholder(in context: Context) -> FaceEntry {
        FaceEntry(date: .now, snapshot: FaceSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (FaceEntry) -> Void) {
        completion(FaceEntry(date: .now, snapshot: FaceSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FaceEntry>) -> Void) {
        let snapshot = FaceSnapshot.load()
        // Минутная сетка на час вперёд: время идёт само, данные обновит приложение.
        let entries = (0..<60).map { offset in
            FaceEntry(date: Date().addingTimeInterval(Double(offset) * 60), snapshot: snapshot)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Круглое: часы сегментами

struct LCDCircularView: View {
    var entry: FaceEntry

    var body: some View {
        let theme = entry.snapshot.theme
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                SegmentText(text: TimeFormat.hhmm(entry.date),
                            style: .seven,
                            color: theme.ink,
                            ghostOpacity: theme.ghostOpacity,
                            digitWidth: 9,
                            digitHeight: 14,
                            spacing: 1,
                            weight: 0.2)
                if let heartRate = entry.snapshot.heartRate {
                    Text("\(heartRate)")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .widgetLabel("GX")
    }
}

// MARK: - Прямоугольное: полоса LCD с данными

struct LCDRectangularView: View {
    var entry: FaceEntry

    var body: some View {
        let theme = entry.snapshot.theme
        let snapshot = entry.snapshot
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(TimeFormat.weekday(entry.date))
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                Text(TimeFormat.dayMonth(entry.date))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                Spacer()
                if snapshot.stopwatchRunning {
                    Text("LAP").font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(theme.accent)
                }
            }
            .foregroundStyle(theme.ink.opacity(0.8))

            SegmentText(text: TimeFormat.hhmm(entry.date),
                        style: .seven,
                        color: theme.ink,
                        ghostOpacity: theme.ghostOpacity,
                        digitWidth: 15,
                        digitHeight: 24,
                        spacing: 1.5,
                        weight: 0.19)

            HStack(spacing: 6) {
                dataChip("HR", snapshot.heartRate.map(String.init) ?? "--", theme.accent, theme)
                dataChip("STP", snapshot.steps.map { $0 > 999 ? "\($0 / 1000).\(($0 % 1000) / 100)K" : "\($0)" } ?? "--", theme.ink, theme)
                dataChip("BAT", snapshot.batteryPercent.map { "\($0)%" } ?? "--", theme.ink, theme)
            }
        }
        .containerBackground(theme.glass.opacity(0.35), for: .widget)
    }

    private func dataChip(_ label: String, _ value: String, _ tint: Color, _ theme: FaceTheme) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.ink.opacity(0.5))
            Text(value)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Угловое и строчное

struct LCDCornerView: View {
    var entry: FaceEntry

    var body: some View {
        let theme = entry.snapshot.theme
        Text(entry.snapshot.heartRate.map { "\($0)" } ?? "--")
            .font(.system(size: 16, weight: .heavy, design: .monospaced))
            .foregroundStyle(theme.ink)
            .widgetLabel {
                Gauge(value: Double(entry.snapshot.movePercent ?? 0), in: 0...100) {
                    Text("MOVE")
                } currentValueLabel: {
                    Text("\(entry.snapshot.movePercent ?? 0)%")
                }
                .tint(theme.accent)
            }
    }
}

struct LCDInlineView: View {
    var entry: FaceEntry

    var body: some View {
        let snapshot = entry.snapshot
        Text("GX \(TimeFormat.hhmm(entry.date)) · \(snapshot.heartRate.map { "\($0)BPM" } ?? "--") · \(snapshot.steps.map { "\($0)" } ?? "--")")
            .font(.system(.body, design: .monospaced))
    }
}

// MARK: - Регистрация

struct GXUltraComplication: Widget {
    let kind = "GXUltraComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FaceProvider()) { entry in
            ComplicationSwitch(entry: entry)
        }
        .configurationDisplayName("GX-ULTRA")
        .description("LCD-модуль: время, пульс, шаги, батарея.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}

struct ComplicationSwitch: View {
    @Environment(\.widgetFamily) private var family
    var entry: FaceEntry

    var body: some View {
        switch family {
        case .accessoryRectangular: LCDRectangularView(entry: entry)
        case .accessoryCorner: LCDCornerView(entry: entry)
        case .accessoryInline: LCDInlineView(entry: entry)
        default: LCDCircularView(entry: entry)
        }
    }
}

@main
struct GXUltraComplicationBundle: WidgetBundle {
    var body: some Widget {
        GXUltraComplication()
    }
}
