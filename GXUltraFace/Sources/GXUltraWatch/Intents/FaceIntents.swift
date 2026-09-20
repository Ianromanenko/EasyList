import AppIntents
import SwiftUI

/// Боковая кнопка «Действие» на Ultra умеет запускать ярлык.
/// Эти интенты — то, что в него можно положить: старт секундомера,
/// подсветка, переключение режима, быстрая тренировка.

struct ToggleStopwatchIntent: AppIntent {
    static var title: LocalizedStringResource = "Секундомер: старт/стоп"
    static var description = IntentDescription("Запускает или останавливает секундомер циферблата GX-ULTRA.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let engine = FaceEngine.shared
        engine.select(.stopwatch)
        engine.stopwatch.toggle()
        return .result()
    }
}

struct LapIntent: AppIntent {
    static var title: LocalizedStringResource = "Секундомер: круг"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        FaceEngine.shared.stopwatch.lap()
        return .result()
    }
}

struct BacklightIntent: AppIntent {
    static var title: LocalizedStringResource = "Подсветка LCD"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        FaceEngine.shared.flashBacklight()
        return .result()
    }
}

struct MarkBearingIntent: AppIntent {
    static var title: LocalizedStringResource = "Компас: отметить направление"
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let engine = FaceEngine.shared
        engine.select(.compass)
        engine.location.markCurrentBearing()
        return .result()
    }
}

struct SwitchModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Открыть режим"
    static var openAppWhenRun = true

    @Parameter(title: "Режим")
    var mode: FaceModeEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        if let target = FaceMode(rawValue: mode.id) {
            FaceEngine.shared.select(target)
        }
        return .result()
    }
}

/// Обёртка над FaceMode для Shortcuts.
struct FaceModeEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Режим циферблата"
    static var defaultQuery = FaceModeQuery()

    var id: String
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    static var all: [FaceModeEntity] {
        FaceMode.allCases.map { FaceModeEntity(id: $0.rawValue, title: "\($0.code) — \($0.title)") }
    }
}

struct FaceModeQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FaceModeEntity] {
        FaceModeEntity.all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [FaceModeEntity] {
        FaceModeEntity.all
    }
}

struct GXUltraShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ToggleStopwatchIntent(),
                    phrases: ["Секундомер в \(.applicationName)", "Start stopwatch in \(.applicationName)"],
                    shortTitle: "Секундомер",
                    systemImageName: "stopwatch")
        AppShortcut(intent: BacklightIntent(),
                    phrases: ["Подсветка в \(.applicationName)"],
                    shortTitle: "Подсветка",
                    systemImageName: "lightbulb")
        AppShortcut(intent: MarkBearingIntent(),
                    phrases: ["Отметить направление в \(.applicationName)"],
                    shortTitle: "Азимут",
                    systemImageName: "location.north.line")
    }
}
