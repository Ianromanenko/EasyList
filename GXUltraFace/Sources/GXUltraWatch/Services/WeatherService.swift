import Foundation
import CoreLocation
import Observation
#if canImport(WeatherKit)
import WeatherKit
#endif

/// Погода для модулей TEMP/SUN. WeatherKit требует capability в аккаунте
/// разработчика; если его нет — модуль просто показывает «--», а не падает.
@MainActor
@Observable
final class WeatherService {
    var temperature: Double?        // °C
    var feelsLike: Double?
    var conditionCode: String?
    var uvIndex: Int?
    var windSpeed: Double?          // м/с
    var precipitationChance: Double?
    var lastUpdate: Date?
    var isAvailable = true

    func refresh(for coordinate: CLLocationCoordinate2D?) async {
        guard let coordinate else { return }
        #if canImport(WeatherKit)
        do {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let weather = try await WeatherKit.WeatherService.shared.weather(for: location)
            temperature = weather.currentWeather.temperature.converted(to: .celsius).value
            feelsLike = weather.currentWeather.apparentTemperature.converted(to: .celsius).value
            conditionCode = weather.currentWeather.condition.rawValue.uppercased()
            uvIndex = weather.currentWeather.uvIndex.value
            windSpeed = weather.currentWeather.wind.speed.converted(to: .metersPerSecond).value
            precipitationChance = weather.hourlyForecast.first?.precipitationChance
            lastUpdate = .now
            isAvailable = true
        } catch {
            isAvailable = false
        }
        #else
        isAvailable = false
        #endif
    }

    /// Короткий код для 14-сегментной строки: CLER, RAIN, SNOW, CLDY...
    var shortCode: String {
        guard let conditionCode else { return "----" }
        switch conditionCode {
        case let code where code.contains("RAIN") || code.contains("DRIZZLE"): return "RAIN"
        case let code where code.contains("SNOW") || code.contains("SLEET"): return "SNOW"
        case let code where code.contains("CLOUD"): return "CLDY"
        case let code where code.contains("CLEAR") || code.contains("SUN"): return "CLER"
        case let code where code.contains("THUNDER"): return "STRM"
        case let code where code.contains("FOG") || code.contains("HAZE"): return "FOG"
        case let code where code.contains("WIND"): return "WIND"
        default: return String(conditionCode.prefix(4))
        }
    }
}
