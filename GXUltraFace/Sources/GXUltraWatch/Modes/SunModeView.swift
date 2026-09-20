import SwiftUI

/// Солнце и луна: восход, закат, солнечный полдень, золотой час и фаза Луны.
/// Считается локально по координатам — работает без сети.
struct SunModeView: View {
    var engine: FaceEngine
    var now: Date
    var isDimmed: Bool

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)
        let info = engine.location.coordinate.map { SolarCalculator.dayInfo(for: now, coordinate: $0) }
        let moon = SolarCalculator.moonInfo(for: now)

        VStack(spacing: 6) {
            HStack(spacing: 8) {
                DataCell(label: "SUNRISE",
                         value: info?.sunrise.map { TimeFormat.hhmm($0) } ?? "--:--",
                         unit: nil, theme: theme, isDimmed: isDimmed,
                         accented: info?.isDaylight(at: now) == false)
                DataCell(label: "SUNSET",
                         value: info?.sunset.map { TimeFormat.hhmm($0) } ?? "--:--",
                         unit: nil, theme: theme, isDimmed: isDimmed,
                         accented: info?.isDaylight(at: now) == true)
            }
            .padding(.horizontal, 8)

            // Солнечная шкала: сколько светового дня прошло и сколько осталось.
            VStack(alignment: .leading, spacing: 2) {
                SegmentBar(value: info?.progress(at: now) ?? 0,
                           cells: 24,
                           color: ink,
                           ghostOpacity: theme.ghostOpacity,
                           cellHeight: 6,
                           spacing: 1.5,
                           overflowColor: theme.accent)
                HStack {
                    LCDLabel("ДЕНЬ " + (info?.dayLength.map { TimeFormat.duration($0) } ?? "--"),
                             color: ink, size: 9, opacity: 0.6)
                    Spacer()
                    LCDLabel(remainingLabel(info), color: theme.accent, size: 9, opacity: 1)
                }
            }
            .padding(.horizontal, 8)

            HStack(spacing: 8) {
                DataCell(label: "GOLDEN",
                         value: info?.goldenHourStart.map { TimeFormat.hhmm($0) } ?? "--:--",
                         unit: nil, theme: theme, isDimmed: isDimmed)
                DataCell(label: "NOON",
                         value: info.map { TimeFormat.hhmm($0.solarNoon) } ?? "--:--",
                         unit: nil, theme: theme, isDimmed: isDimmed)
            }
            .padding(.horizontal, 8)

            HStack(spacing: 8) {
                MoonGlyph(phase: moon.phase, color: ink, accent: theme.accent)
                    .frame(width: 26, height: 26)
                VStack(alignment: .leading, spacing: 1) {
                    SegmentText(text: moon.name,
                                style: .fourteen,
                                color: ink,
                                ghostOpacity: theme.ghostOpacity,
                                digitWidth: 9,
                                digitHeight: 14,
                                spacing: 1.5,
                                weight: 0.2,
                                showsGhosts: false)
                    LCDLabel("\(Int(moon.illumination * 100))% · \(String(format: "%.1f", moon.ageDays))d",
                             color: ink, size: 9, opacity: 0.6)
                }
                Spacer()
            }
            .padding(.horizontal, 10)

            if engine.location.coordinate == nil {
                LCDLabel("НЕТ ГЕОПОЗИЦИИ", color: theme.accent, size: 9, opacity: 1)
            }
        }
    }

    private func remainingLabel(_ info: SolarCalculator.DayInfo?) -> String {
        guard let info else { return "" }
        if let sunset = info.sunset, info.isDaylight(at: now) {
            return "ДО ЗАКАТА " + TimeFormat.duration(sunset.timeIntervalSince(now))
        }
        if let sunrise = info.sunrise {
            let next = sunrise > now ? sunrise : sunrise.addingTimeInterval(86400)
            return "ДО ВОСХОДА " + TimeFormat.duration(next.timeIntervalSince(now))
        }
        return ""
    }
}

/// Луна рисуется терминатором, а не иконкой: видно и фазу, и её направление.
struct MoonGlyph: View {
    var phase: Double
    var color: Color
    var accent: Color

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            context.stroke(Circle().path(in: rect), with: .color(color.opacity(0.4)), lineWidth: 1)

            let radius = rect.width / 2
            let center = CGPoint(x: rect.midX, y: rect.midY)
            // Смещение терминатора: -1 (новолуние) ... 1 (новолуние с другой стороны)
            let k = cos(2 * .pi * phase)
            var path = Path()
            path.move(to: CGPoint(x: center.x, y: center.y - radius))
            path.addArc(center: center, radius: radius,
                        startAngle: .degrees(-90), endAngle: .degrees(90),
                        clockwise: phase > 0.5)
            path.addCurve(to: CGPoint(x: center.x, y: center.y - radius),
                          control1: CGPoint(x: center.x - radius * k * 1.33, y: center.y + radius * 0.55),
                          control2: CGPoint(x: center.x - radius * k * 1.33, y: center.y - radius * 0.55))
            context.fill(path, with: .color(accent.opacity(0.85)))
        }
    }
}
