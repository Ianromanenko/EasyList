import SwiftUI

/// Компас с настоящей шкалой: курс, румб, отметка направления (bearing lock)
/// и расстояние до отмеченной точки — минимальный «Wayfinder» на LCD.
struct CompassModeView: View {
    var engine: FaceEngine
    var isDimmed: Bool

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)
        let heading = engine.location.heading

        VStack(spacing: 4) {
            ZStack {
                CompassDial(heading: heading ?? 0,
                            markedBearing: engine.location.markedBearing,
                            color: ink,
                            accent: theme.accent,
                            ghostOpacity: theme.ghostOpacity)

                VStack(spacing: 0) {
                    SegmentText(text: heading.map { String(format: "%03d", Int($0.rounded())) } ?? "---",
                                style: .seven,
                                color: ink,
                                ghostOpacity: theme.ghostOpacity,
                                digitWidth: 18,
                                digitHeight: 28,
                                spacing: 2,
                                weight: 0.19)
                    LCDLabel(heading.map { LocationService.cardinal(for: $0) } ?? "--",
                             color: theme.accent, size: 12, opacity: 1)
                }
            }
            .frame(height: 110)

            HStack(spacing: 8) {
                DataCell(label: "MARK",
                         value: engine.location.markedBearing.map { String(format: "%03d", Int($0)) } ?? "---",
                         unit: "°", theme: theme, isDimmed: isDimmed,
                         accented: engine.location.markedBearing != nil)
                DataCell(label: "DIST",
                         value: engine.location.distanceToMark.map { $0 > 1000
                             ? String(format: "%.1f", $0 / 1000)
                             : String(Int($0)) } ?? "---",
                         unit: (engine.location.distanceToMark ?? 0) > 1000 ? "KM" : "M",
                         theme: theme, isDimmed: isDimmed)
            }
            .padding(.horizontal, 8)

            if (engine.location.headingAccuracy ?? 0) > 15 {
                LCDLabel("КАЛИБРОВКА: ВОСЬМЁРКА", color: theme.accent, size: 9, opacity: 1)
            }
        }
    }
}

/// Шкала компаса: вращается сама картушка, а не стрелка — как в настоящем приборе.
struct CompassDial: View {
    var heading: Double
    var markedBearing: Double?
    var color: Color
    var accent: Color
    var ghostOpacity: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 2

            // Деления через 15°, каждые 90° — длинные.
            for tick in stride(from: 0.0, to: 360.0, by: 15.0) {
                let angle = (tick - heading - 90) * .pi / 180
                let isMajor = tick.truncatingRemainder(dividingBy: 90) == 0
                let inner = radius - (isMajor ? 14 : 7)
                var path = Path()
                path.move(to: CGPoint(x: center.x + cos(angle) * inner,
                                      y: center.y + sin(angle) * inner))
                path.addLine(to: CGPoint(x: center.x + cos(angle) * radius,
                                         y: center.y + sin(angle) * radius))
                context.stroke(path,
                               with: .color(isMajor ? color : color.opacity(0.45)),
                               lineWidth: isMajor ? 2 : 1)
            }

            // Буквы сторон света едут вместе со шкалой.
            let labels: [(String, Double)] = [("N", 0), ("E", 90), ("S", 180), ("W", 270)]
            for (label, degrees) in labels {
                let angle = (degrees - heading - 90) * .pi / 180
                let point = CGPoint(x: center.x + cos(angle) * (radius - 26),
                                    y: center.y + sin(angle) * (radius - 26))
                let text = Text(label)
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundColor(label == "N" ? accent : color)
                context.draw(text, at: point)
            }

            // Отмеченное направление — треугольник по краю шкалы.
            if let markedBearing {
                let angle = (markedBearing - heading - 90) * .pi / 180
                var marker = Path()
                let tip = CGPoint(x: center.x + cos(angle) * radius,
                                  y: center.y + sin(angle) * radius)
                let left = CGPoint(x: center.x + cos(angle - 0.12) * (radius - 12),
                                   y: center.y + sin(angle - 0.12) * (radius - 12))
                let right = CGPoint(x: center.x + cos(angle + 0.12) * (radius - 12),
                                    y: center.y + sin(angle + 0.12) * (radius - 12))
                marker.move(to: tip)
                marker.addLine(to: left)
                marker.addLine(to: right)
                marker.closeSubpath()
                context.fill(marker, with: .color(accent))
            }

            // Неподвижный указатель «куда смотрит корпус».
            var pointer = Path()
            pointer.move(to: CGPoint(x: center.x, y: center.y - radius - 1))
            pointer.addLine(to: CGPoint(x: center.x - 5, y: center.y - radius + 9))
            pointer.addLine(to: CGPoint(x: center.x + 5, y: center.y - radius + 9))
            pointer.closeSubpath()
            context.fill(pointer, with: .color(color))
        }
    }
}
