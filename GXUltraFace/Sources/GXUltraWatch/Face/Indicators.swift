import SwiftUI

/// Casio-шкала: ряд ячеек, которые загораются слева направо.
/// Используется для колец активности, батареи, заряда тренировки.
struct SegmentBar: View {
    var value: Double            // 0...1
    var cells: Int = 12
    var color: Color
    var ghostOpacity: Double = 0.14
    var cellHeight: CGFloat = 8
    var spacing: CGFloat = 2
    /// Значение больше 1.0 (перевыполненная цель) подсвечивается акцентом.
    var overflowColor: Color?

    var body: some View {
        let filled = Int((min(value, 1.0) * Double(cells)).rounded(.down))
        let overflow = value > 1.0
        HStack(spacing: spacing) {
            ForEach(0..<cells, id: \.self) { index in
                Rectangle()
                    .fill(index < filled
                          ? (overflow ? (overflowColor ?? color) : color)
                          : color.opacity(ghostOpacity))
            }
        }
        .frame(height: cellHeight)
    }
}

/// Столбики истории (давление за 6 часов, пульс за час, темп набора высоты).
struct MiniHistogram: View {
    var values: [Double]
    var color: Color
    var ghostOpacity: Double = 0.14
    var barCount: Int = 24

    var body: some View {
        let sample = Self.resample(values, to: barCount)
        let lo = sample.min() ?? 0
        let hi = sample.max() ?? 1
        let span = max(hi - lo, 0.0001)
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 1.5) {
                ForEach(Array(sample.enumerated()), id: \.offset) { _, value in
                    let ratio = (value - lo) / span
                    Rectangle()
                        .fill(color)
                        .frame(height: max(geo.size.height * CGFloat(0.12 + 0.88 * ratio), 1.5))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .background(alignment: .bottom) {
                Rectangle().fill(color.opacity(ghostOpacity)).frame(height: 1)
            }
        }
    }

    /// История приходит неравномерной — приводим к фиксированному числу столбиков.
    static func resample(_ values: [Double], to count: Int) -> [Double] {
        guard !values.isEmpty else { return Array(repeating: 0, count: count) }
        guard values.count > count else { return values }
        let bucket = Double(values.count) / Double(count)
        return (0..<count).map { index in
            let start = Int(Double(index) * bucket)
            let end = min(Int(Double(index + 1) * bucket), values.count)
            let slice = values[start..<max(end, start + 1)]
            return slice.reduce(0, +) / Double(slice.count)
        }
    }
}

/// Мелкая надпись-индикатор в духе «ALARM · CHIME · DST».
/// Гаснет, но не исчезает — контур остаётся, как на настоящем стекле.
struct IndicatorLamp: View {
    var title: String
    var isOn: Bool
    var color: Color
    var ghostOpacity: Double = 0.16
    var size: CGFloat = 9

    var body: some View {
        Text(title)
            .font(.system(size: size, weight: .heavy, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(color.opacity(isOn ? 1 : ghostOpacity))
            .accessibilityLabel("\(title) \(isOn ? "включено" : "выключено")")
    }
}

/// Техническая подпись LCD (единицы, названия полей).
struct LCDLabel: View {
    var text: String
    var color: Color
    var size: CGFloat = 10
    var opacity: Double = 0.75

    init(_ text: String, color: Color, size: CGFloat = 10, opacity: Double = 0.75) {
        self.text = text
        self.color = color
        self.size = size
        self.opacity = opacity
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .monospaced))
            .tracking(0.8)
            .foregroundStyle(color.opacity(opacity))
    }
}

/// Рамка модуля — тонкая гравировка на стекле, разделяющая зоны.
struct LCDFrame<Content: View>: View {
    var color: Color
    var title: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title {
                LCDLabel(title, color: color, size: 9, opacity: 0.55)
            }
            content
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
    }
}
