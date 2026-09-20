import SwiftUI

/// Высотомер и барометр: абсолютная высота, набор от нулевой отметки,
/// давление и его тренд за последние часы — из тренда и растёт «прогноз».
struct BaroModeView: View {
    var engine: FaceEngine
    var isDimmed: Bool

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)
        let motion = engine.motion
        let altitude = motion.absoluteAltitude ?? engine.location.altitudeGPS

        VStack(spacing: 5) {
            HStack(alignment: .bottom, spacing: 4) {
                BigReadout(text: altitude.map { String(Int($0.rounded())) } ?? "----",
                           theme: theme,
                           isDimmed: isDimmed,
                           digitWidth: 26,
                           digitHeight: 40)
                .layoutPriority(1)
                LCDLabel("M", color: theme.accent, size: 12, opacity: 1)
                    .padding(.bottom, 5)
            }

            HStack(spacing: 8) {
                DataCell(label: "ОТ НУЛЯ",
                         value: String(format: "%+d", Int(motion.relativeAltitude.rounded())),
                         unit: "M", theme: theme, isDimmed: isDimmed,
                         accented: abs(motion.relativeAltitude) > 10)
                DataCell(label: "PRESS",
                         value: motion.pressureHPa.map { String(Int($0.rounded())) } ?? "----",
                         unit: "HPA", theme: theme, isDimmed: isDimmed)
            }
            .padding(.horizontal, 8)

            if !isDimmed && motion.pressureHistory.count > 4 {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        LCDLabel("ТРЕНД ДАВЛЕНИЯ", color: ink, size: 9, opacity: 0.5)
                        Spacer()
                        SegmentText(text: motion.pressureTrend.code,
                                    style: .fourteen,
                                    color: theme.accent,
                                    ghostOpacity: theme.ghostOpacity,
                                    digitWidth: 8,
                                    digitHeight: 12,
                                    spacing: 1,
                                    weight: 0.2,
                                    showsGhosts: false)
                    }
                    MiniHistogram(values: motion.pressureHistory,
                                  color: ink,
                                  ghostOpacity: theme.ghostOpacity,
                                  barCount: 30)
                    .frame(height: 28)
                }
                .padding(.horizontal, 8)
            }

            HStack(spacing: 8) {
                DataCell(label: "ПРОГНОЗ",
                         value: motion.pressureTrend.forecast,
                         unit: nil, theme: theme, isDimmed: isDimmed, accented: true)
                DataCell(label: "TEMP",
                         value: engine.weather.temperature.map { String(Int($0.rounded())) } ?? "--",
                         unit: "°C", theme: theme, isDimmed: isDimmed)
            }
            .padding(.horizontal, 8)

            if !motion.isAvailable {
                LCDLabel("БАРОМЕТР НЕДОСТУПЕН", color: theme.accent, size: 9, opacity: 1)
            }
        }
    }
}
