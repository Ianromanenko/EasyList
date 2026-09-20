import SwiftUI
import WatchKit

@main
struct GXUltraApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            FaceView()
        }
        // Фоновое обновление: раз в 15 минут подтягиваем кольца, погоду и батарею,
        // чтобы при подъёме руки цифры уже были свежими.
        .backgroundTask(.appRefresh("gxultra.refresh")) {
            await MainActor.run {
                let engine = FaceEngine.shared
                engine.refreshPeriodic()
                engine.scheduleBackgroundRefresh()
            }
        }
    }
}
