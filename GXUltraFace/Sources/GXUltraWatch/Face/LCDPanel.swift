import SwiftUI

/// Стекло дисплея: подложка, пиксельная сетка, виньетка и EL-подсветка.
/// Без этого сегменты выглядят как обычный текст, а не как LCD.
struct LCDBackground: View {
    var theme: FaceTheme
    var isBacklit: Bool
    var isDimmed: Bool

    var body: some View {
        ZStack {
            Rectangle().fill(theme.glass)

            // Подсветка заливает стекло изнутри и слегка «переэкспонирует» край.
            if isBacklit {
                RadialGradient(colors: [theme.backlight.opacity(0.85), theme.backlight.opacity(0.25)],
                               center: .center,
                               startRadius: 4,
                               endRadius: 220)
                .blendMode(.screen)
                .transition(.opacity)
            }

            PixelGrid(color: theme.ink.opacity(0.05))

            // Виньетка: у настоящего STN края чуть темнее.
            RadialGradient(colors: [.clear, .black.opacity(0.35)],
                           center: .center,
                           startRadius: 60,
                           endRadius: 230)
        }
        .opacity(isDimmed ? 0.85 : 1)
        .animation(.easeOut(duration: 0.18), value: isBacklit)
        .ignoresSafeArea()
    }
}

/// Едва заметная матрица пикселей — читается только вблизи, но именно она
/// делает картинку «дисплеем», а не плоской заливкой.
private struct PixelGrid: View {
    var color: Color

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 3
            var path = Path()
            var x: CGFloat = 0
            while x < size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(path, with: .color(color), lineWidth: 0.4)
        }
        .allowsHitTesting(false)
    }
}

/// Верхняя строка: режим, индикаторы и батарея. Ничего декоративного —
/// каждая лампочка отражает реальное состояние.
struct StatusStrip: View {
    var engine: FaceEngine
    var isDimmed: Bool

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)

        HStack(alignment: .center, spacing: 6) {
            SegmentText(text: engine.mode.code,
                        style: .fourteen,
                        color: theme.accent,
                        ghostOpacity: theme.ghostOpacity,
                        digitWidth: 8,
                        digitHeight: 13,
                        spacing: 1.5,
                        weight: 0.2,
                        showsGhosts: false)

            IndicatorLamp(title: "ALM", isOn: engine.alarms.hasEnabledAlarm, color: ink)
            IndicatorLamp(title: "SIG", isOn: engine.settings.hourlyChime, color: ink)
            IndicatorLamp(title: "LAP", isOn: engine.stopwatch.isRunning, color: ink)

            Spacer(minLength: 0)

            if engine.battery.isCharging {
                IndicatorLamp(title: "CHG", isOn: true, color: theme.accent)
            }

            SegmentBar(value: engine.battery.level,
                       cells: 5,
                       color: engine.battery.level < 0.15 ? theme.accent : ink,
                       ghostOpacity: theme.ghostOpacity,
                       cellHeight: 7,
                       spacing: 1.5)
            .frame(width: 26)

            LCDLabel("\(engine.battery.percent)%", color: ink, size: 10, opacity: 0.9)
        }
        .frame(height: 14)
        .padding(.horizontal, 8)
    }
}

/// Нижний ряд кнопок корпуса. Подписи меняются под режим.
struct SoftKeyBar: View {
    var keys: [SoftKey]
    var theme: FaceTheme
    var isDimmed: Bool

    var body: some View {
        HStack(spacing: 4) {
            ForEach(keys) { key in
                Button(action: key.action) {
                    Text(key.label)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(key.isAccented ? theme.glass : theme.ink(dimmed: isDimmed))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(key.isAccented ? theme.accent.opacity(isDimmed ? 0.5 : 1) : theme.ink.opacity(0.10))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .opacity(isDimmed ? 0.7 : 1)
    }
}
