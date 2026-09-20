import SwiftUI

/// FROGMAN: датчик погружения Apple Watch Ultra — глубина, максимум за заплыв
/// и температура воды. Не замена дайв-компьютеру: это индикатор, не прибор.
struct DiveModeView: View {
    var engine: FaceEngine
    var isDimmed: Bool

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)
        let water = engine.water

        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 4) {
                BigReadout(text: water.depth.map { String(format: "%.1f", $0) } ?? "--.-",
                           theme: theme,
                           isDimmed: isDimmed,
                           digitWidth: 28,
                           digitHeight: 44)
                .layoutPriority(1)
                LCDLabel("M", color: theme.accent, size: 12, opacity: 1)
                    .padding(.bottom, 6)
            }

            SegmentBar(value: (water.depth ?? 0) / 40,
                       cells: 20,
                       color: (water.depth ?? 0) > 30 ? theme.accent : ink,
                       ghostOpacity: theme.ghostOpacity,
                       cellHeight: 6,
                       spacing: 1.5)
            .padding(.horizontal, 10)

            HStack(spacing: 8) {
                DataCell(label: "MAX",
                         value: String(format: "%.1f", water.maxDepthThisDive),
                         unit: "M", theme: theme, isDimmed: isDimmed, accented: true)
                DataCell(label: "WATER",
                         value: water.waterTemperature.map { String(format: "%.1f", $0) } ?? "--",
                         unit: "°C", theme: theme, isDimmed: isDimmed)
            }
            .padding(.horizontal, 8)

            HStack(spacing: 6) {
                IndicatorLamp(title: "SUBMERGED", isOn: water.submerged, color: theme.accent, size: 10)
                Spacer()
                LCDLabel(water.isSupported ? "SENSOR OK" : "НЕТ ДАТЧИКА", color: ink, size: 9, opacity: 0.6)
            }
            .padding(.horizontal, 10)
        }
    }
}
