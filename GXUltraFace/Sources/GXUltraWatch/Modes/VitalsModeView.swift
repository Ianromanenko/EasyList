import SwiftUI

/// Пульс здесь и сейчас + контекст: покой, HRV, нагрузка относительно покоя
/// и часовая гистограмма. Цифра без контекста бесполезна — контекст и даёт смысл.
struct VitalsModeView: View {
    var engine: FaceEngine
    var isDimmed: Bool

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)
        let health = engine.health

        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 6) {
                BigReadout(text: health.heartRate.map { String(format: "%3d", Int($0)) } ?? "---",
                           theme: theme,
                           isDimmed: isDimmed,
                           digitWidth: 30,
                           digitHeight: 46)
                .layoutPriority(1)
                VStack(alignment: .leading, spacing: 0) {
                    LCDLabel("BPM", color: theme.accent, size: 11, opacity: 1)
                    LCDLabel(strainCode, color: ink, size: 10, opacity: 0.7)
                }
                .padding(.bottom, 6)
            }

            HStack(spacing: 8) {
                DataCell(label: "REST",
                         value: health.restingHeartRate.map { String(Int($0)) } ?? "--",
                         unit: "BPM", theme: theme, isDimmed: isDimmed)
                DataCell(label: "HRV",
                         value: health.hrv.map { String(Int($0)) } ?? "--",
                         unit: "MS", theme: theme, isDimmed: isDimmed)
            }
            .padding(.horizontal, 8)

            HStack(spacing: 8) {
                DataCell(label: "STEPS",
                         value: String(max(health.steps, engine.motion.currentSteps)),
                         unit: nil, theme: theme, isDimmed: isDimmed)
                DataCell(label: "DIST",
                         value: String(format: "%.2f", health.distanceMeters / 1000),
                         unit: "KM", theme: theme, isDimmed: isDimmed)
            }
            .padding(.horizontal, 8)

            if !isDimmed && health.heartRateSamples.count > 4 {
                VStack(alignment: .leading, spacing: 2) {
                    LCDLabel("LAST 60 MIN", color: ink, size: 9, opacity: 0.5)
                    MiniHistogram(values: health.heartRateSamples,
                                  color: theme.accent,
                                  ghostOpacity: theme.ghostOpacity,
                                  barCount: 28)
                    .frame(height: 26)
                }
                .padding(.horizontal, 8)
            }
        }
    }

    /// Насколько текущий пульс выше покоя: спокойный ориентир без медицинских обещаний.
    private var strainCode: String {
        guard let ratio = engine.health.strainIndex else { return "--" }
        switch ratio {
        case ..<1.15: return "CALM"
        case ..<1.4: return "LIGHT"
        case ..<1.8: return "WORK"
        default: return "HARD"
        }
    }
}
