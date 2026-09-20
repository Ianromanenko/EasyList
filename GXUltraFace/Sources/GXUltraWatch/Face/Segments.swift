import SwiftUI

// MARK: - Сегментный движок
//
// Ни один системный шрифт не даёт настоящий LCD: у настоящего дисплея видны
// ВЫКЛЮЧЕННЫЕ сегменты ("призраки"). Поэтому цифры рисуются вручную:
// 7 сегментов для чисел, 14 — для букв (день недели, режим, единицы).

enum Seg: Hashable {
    case a, b, c, d, e, f      // внешний контур
    case g                     // средняя перекладина (7-сегментный режим)
    case g1, g2                // левая/правая половины перекладины (14-сегментный)
    case i, l                  // центральные вертикали
    case h, j, k, m            // диагонали
}

enum SegStyle {
    case seven
    case fourteen
}

enum SegmentFont {
    static let seven: [Character: Set<Seg>] = [
        "0": [.a, .b, .c, .d, .e, .f],
        "1": [.b, .c],
        "2": [.a, .b, .g, .e, .d],
        "3": [.a, .b, .c, .d, .g],
        "4": [.f, .g, .b, .c],
        "5": [.a, .f, .g, .c, .d],
        "6": [.a, .f, .e, .d, .c, .g],
        "7": [.a, .b, .c],
        "8": [.a, .b, .c, .d, .e, .f, .g],
        "9": [.a, .b, .c, .d, .f, .g],
        "-": [.g],
        " ": [],
        "_": [.d],
        "o": [.c, .d, .e, .g],
        "E": [.a, .d, .e, .f, .g],
        "r": [.e, .g]
    ]

    static let fourteen: [Character: Set<Seg>] = [
        "0": [.a, .b, .c, .d, .e, .f], "1": [.b, .c],
        "2": [.a, .b, .g1, .g2, .e, .d], "3": [.a, .b, .c, .d, .g1, .g2],
        "4": [.f, .g1, .g2, .b, .c], "5": [.a, .f, .g1, .g2, .c, .d],
        "6": [.a, .f, .e, .d, .c, .g1, .g2], "7": [.a, .b, .c],
        "8": [.a, .b, .c, .d, .e, .f, .g1, .g2], "9": [.a, .b, .c, .d, .f, .g1, .g2],
        "A": [.e, .f, .a, .b, .c, .g1, .g2], "B": [.a, .b, .c, .d, .g2, .i, .l],
        "C": [.a, .f, .e, .d], "D": [.a, .b, .c, .d, .i, .l],
        "E": [.a, .f, .e, .d, .g1], "F": [.a, .f, .e, .g1],
        "G": [.a, .f, .e, .d, .c, .g2], "H": [.f, .e, .b, .c, .g1, .g2],
        "I": [.a, .d, .i, .l], "J": [.b, .c, .d, .e],
        "K": [.f, .e, .g1, .j, .k], "L": [.f, .e, .d],
        "M": [.e, .f, .h, .j, .b, .c], "N": [.e, .f, .h, .k, .b, .c],
        "O": [.a, .b, .c, .d, .e, .f], "P": [.a, .b, .e, .f, .g1, .g2],
        "Q": [.a, .b, .c, .d, .e, .f, .k], "R": [.a, .b, .e, .f, .g1, .g2, .k],
        "S": [.a, .f, .g1, .g2, .c, .d], "T": [.a, .i, .l],
        "U": [.b, .c, .d, .e, .f], "V": [.f, .e, .m, .j],
        "W": [.f, .e, .m, .k, .b, .c], "X": [.h, .j, .k, .m],
        "Y": [.h, .j, .l], "Z": [.a, .j, .m, .d],
        "-": [.g1, .g2], "+": [.g1, .g2, .i, .l], "/": [.j, .m],
        "*": [.g1, .g2, .i, .l, .h, .j, .k, .m], "'": [.i],
        "°": [.a, .b, .f, .g1], " ": []
    ]

    static func segments(for char: Character, style: SegStyle) -> Set<Seg> {
        switch style {
        case .seven:
            return seven[char] ?? seven[Character(String(char).uppercased())] ?? []
        case .fourteen:
            return fourteen[Character(String(char).uppercased())] ?? []
        }
    }

    static func allSegments(_ style: SegStyle) -> Set<Seg> {
        switch style {
        case .seven: return [.a, .b, .c, .d, .e, .f, .g]
        case .fourteen: return [.a, .b, .c, .d, .e, .f, .g1, .g2, .i, .l, .h, .j, .k, .m]
        }
    }
}

// MARK: - Геометрия

private struct SegGeometry {
    let size: CGSize
    let t: CGFloat        // толщина сегмента
    let gap: CGFloat      // зазор между соседними сегментами
    let skew: CGFloat     // наклон, как у настоящего LCD

    init(size: CGSize, weight: CGFloat, skew: CGFloat) {
        self.size = size
        self.t = min(size.width, size.height) * weight
        self.gap = t * 0.22
        self.skew = skew
    }

    /// Наклон применяется к каждой точке: верх уезжает вправо.
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x + (size.height - y) * skew, y: y)
    }

    /// Классический шестиугольный сегмент вдоль горизонтали.
    func horizontal(y: CGFloat, x0: CGFloat, x1: CGFloat) -> Path {
        let h = t / 2
        var path = Path()
        path.move(to: p(x0, y))
        path.addLine(to: p(x0 + h, y - h))
        path.addLine(to: p(x1 - h, y - h))
        path.addLine(to: p(x1, y))
        path.addLine(to: p(x1 - h, y + h))
        path.addLine(to: p(x0 + h, y + h))
        path.closeSubpath()
        return path
    }

    func vertical(x: CGFloat, y0: CGFloat, y1: CGFloat) -> Path {
        let h = t / 2
        var path = Path()
        path.move(to: p(x, y0))
        path.addLine(to: p(x + h, y0 + h))
        path.addLine(to: p(x + h, y1 - h))
        path.addLine(to: p(x, y1))
        path.addLine(to: p(x - h, y1 - h))
        path.addLine(to: p(x - h, y0 + h))
        path.closeSubpath()
        return path
    }

    func diagonal(from a: CGPoint, to b: CGPoint) -> Path {
        var path = Path()
        path.move(to: p(a.x, a.y))
        path.addLine(to: p(b.x, b.y))
        return path.strokedPath(.init(lineWidth: t * 0.62, lineCap: .round))
    }

    func path(for seg: Seg) -> Path {
        let w = size.width, h = size.height
        let half = t / 2
        let midY = h / 2
        let left = half, right = w - half
        let cx = w / 2

        switch seg {
        case .a:  return horizontal(y: half, x0: left + gap, x1: right - gap)
        case .d:  return horizontal(y: h - half, x0: left + gap, x1: right - gap)
        case .g:  return horizontal(y: midY, x0: left + gap, x1: right - gap)
        case .g1: return horizontal(y: midY, x0: left + gap, x1: cx - gap * 0.5)
        case .g2: return horizontal(y: midY, x0: cx + gap * 0.5, x1: right - gap)
        case .f:  return vertical(x: left, y0: half + gap, y1: midY - gap)
        case .b:  return vertical(x: right, y0: half + gap, y1: midY - gap)
        case .e:  return vertical(x: left, y0: midY + gap, y1: h - half - gap)
        case .c:  return vertical(x: right, y0: midY + gap, y1: h - half - gap)
        case .i:  return vertical(x: cx, y0: half + gap, y1: midY - gap)
        case .l:  return vertical(x: cx, y0: midY + gap, y1: h - half - gap)
        case .h:  return diagonal(from: CGPoint(x: left + gap, y: half + gap * 1.6),
                                  to: CGPoint(x: cx - gap, y: midY - gap * 1.2))
        case .j:  return diagonal(from: CGPoint(x: right - gap, y: half + gap * 1.6),
                                  to: CGPoint(x: cx + gap, y: midY - gap * 1.2))
        case .k:  return diagonal(from: CGPoint(x: cx + gap, y: midY + gap * 1.2),
                                  to: CGPoint(x: right - gap, y: h - half - gap * 1.6))
        case .m:  return diagonal(from: CGPoint(x: cx - gap, y: midY + gap * 1.2),
                                  to: CGPoint(x: left + gap, y: h - half - gap * 1.6))
        }
    }
}

// MARK: - Вьюхи

/// Один сегментный знак вместе с "призраками" выключенных сегментов.
struct SegmentChar: View {
    let char: Character
    var style: SegStyle = .seven
    var color: Color
    var ghostOpacity: Double = 0.12
    var weight: CGFloat = 0.19
    var skew: CGFloat = 0.055
    /// Ghost-слой можно погасить — например, в маленьких подписях.
    var showsGhosts: Bool = true

    var body: some View {
        Canvas(opaque: false) { ctx, size in
            let geo = SegGeometry(size: size, weight: weight, skew: skew)
            let on = SegmentFont.segments(for: char, style: style)
            if showsGhosts {
                for seg in SegmentFont.allSegments(style) where !on.contains(seg) {
                    ctx.fill(geo.path(for: seg), with: .color(color.opacity(ghostOpacity)))
                }
            }
            for seg in on {
                ctx.fill(geo.path(for: seg), with: .color(color))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Строка сегментным шрифтом. Цифры автоматически идут 7-сегментными,
/// буквы — 14-сегментными, как на настоящем модуле Casio.
struct SegmentText: View {
    let text: String
    var style: SegStyle = .seven
    var color: Color
    var ghostOpacity: Double = 0.12
    var digitWidth: CGFloat
    var digitHeight: CGFloat
    var spacing: CGFloat = 3
    var weight: CGFloat = 0.19
    var skew: CGFloat = 0.055
    var showsGhosts: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                switch ch {
                case ":":
                    ColonGlyph(color: color, height: digitHeight, dot: digitWidth * 0.18)
                        .frame(width: digitWidth * 0.34)
                case ".":
                    Circle()
                        .fill(color)
                        .frame(width: digitWidth * 0.17, height: digitWidth * 0.17)
                        .frame(height: digitHeight, alignment: .bottom)
                case " ":
                    Color.clear.frame(width: digitWidth * 0.55, height: digitHeight)
                default:
                    SegmentChar(char: ch,
                                style: style,
                                color: color,
                                ghostOpacity: ghostOpacity,
                                weight: weight,
                                skew: skew,
                                showsGhosts: showsGhosts)
                        .frame(width: digitWidth, height: digitHeight)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(text))
    }
}

/// Двоеточие с «дыханием» раз в секунду — как у кварцевого модуля.
struct ColonGlyph: View {
    var color: Color
    var height: CGFloat
    var dot: CGFloat
    var blinking: Bool = true

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let second = Int(context.date.timeIntervalSinceReferenceDate * 2) % 2
            let visible = !blinking || second == 0
            VStack(spacing: height * 0.18) {
                Circle().fill(color)
                Circle().fill(color)
            }
            .frame(width: dot)
            .frame(height: height * 0.52)
            .opacity(visible ? 1 : 0.18)
        }
        .frame(height: height)
    }
}
