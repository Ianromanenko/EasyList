import WatchKit

/// Тактильный «модуль» часов: кнопки кликают, режимы щёлкают,
/// час отбивается сигналом — ровно как у Casio с включённым SIG.
@MainActor
enum Haptics {
    static func button() { WKInterfaceDevice.current().play(.click) }
    static func modeChange() { WKInterfaceDevice.current().play(.directionUp) }
    static func start() { WKInterfaceDevice.current().play(.start) }
    static func stop() { WKInterfaceDevice.current().play(.stop) }
    static func lap() { WKInterfaceDevice.current().play(.success) }
    static func alarm() { WKInterfaceDevice.current().play(.notification) }
    static func failure() { WKInterfaceDevice.current().play(.failure) }

    /// Часовой сигнал: два коротких щелчка.
    static func hourlyChime() {
        let device = WKInterfaceDevice.current()
        device.play(.click)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(160))
            device.play(.click)
        }
    }
}
