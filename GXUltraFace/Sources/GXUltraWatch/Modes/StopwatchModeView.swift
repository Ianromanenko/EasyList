import SwiftUI

/// Секундомер с сотыми и списком кругов. Сотые обновляются отдельным
/// TimelineView на 20 Гц — остальной циферблат при этом не перерисовывается.
struct StopwatchModeView: View {
    var engine: FaceEngine
    var isDimmed: Bool

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)
        let stopwatch = engine.stopwatch

        VStack(spacing: 5) {
            TimelineView(.periodic(from: .now, by: isDimmed ? 1 : 0.05)) { context in
                let elapsed = stopwatch.elapsed(at: context.date)
                VStack(spacing: 0) {
                    BigReadout(text: StopwatchEngine.format(elapsed, showsHundredths: false),
                               theme: theme,
                               isDimmed: isDimmed,
                               digitWidth: 30,
                               digitHeight: 46)
                    HStack(spacing: 4) {
                        LCDLabel(stopwatch.isRunning ? "RUN" : "HOLD",
                                 color: stopwatch.isRunning ? theme.accent : ink,
                                 size: 10, opacity: 1)
                        SegmentText(text: String(format: ".%02d", Int((elapsed - floor(elapsed)) * 100)),
                                    style: .seven,
                                    color: theme.accent,
                                    ghostOpacity: theme.ghostOpacity,
                                    digitWidth: 12,
                                    digitHeight: 18,
                                    spacing: 1,
                                    weight: 0.2,
                                    showsGhosts: false)
                    }
                }
            }

            if let split = stopwatch.lastSplit, !stopwatch.laps.isEmpty {
                HStack(spacing: 8) {
                    DataCell(label: "LAP \(stopwatch.laps.count)",
                             value: StopwatchEngine.format(split),
                             unit: nil, theme: theme, isDimmed: isDimmed, accented: true)
                    DataCell(label: "AVG",
                             value: StopwatchEngine.format(averageLap),
                             unit: nil, theme: theme, isDimmed: isDimmed)
                }
                .padding(.horizontal, 8)
            }

            if !isDimmed && !stopwatch.laps.isEmpty {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(stopwatch.laps.prefix(8).enumerated()), id: \.offset) { index, lap in
                            HStack {
                                LCDLabel(String(format: "%02d", stopwatch.laps.count - index),
                                         color: ink, size: 10, opacity: 0.5)
                                Spacer()
                                LCDLabel(StopwatchEngine.format(lap), color: ink, size: 11, opacity: 0.9)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
    }

    private var averageLap: TimeInterval {
        let laps = engine.stopwatch.laps
        guard let first = laps.first, !laps.isEmpty else { return 0 }
        return first / Double(laps.count)
    }
}
