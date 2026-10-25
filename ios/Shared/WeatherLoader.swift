import Foundation

/// Today's Vilnius forecast, fetched by the phone itself from Open-Meteo (free, no key),
/// worded the same way as the generator's forecast line.
enum WeatherLoader {
    private static let url = URL(string:
        "https://api.open-meteo.com/v1/forecast?latitude=54.687&longitude=25.28"
        + "&daily=temperature_2m_max,temperature_2m_min,weather_code,wind_speed_10m_max"
        + "&hourly=precipitation_probability&timezone=Europe%2FVilnius&forecast_days=1")!

    private struct Response: Decodable {
        struct Daily: Decodable {
            var temperature_2m_max: [Double]
            var temperature_2m_min: [Double]
            var weather_code: [Int]
            var wind_speed_10m_max: [Double]
        }
        struct Hourly: Decodable {
            var time: [String]
            var precipitation_probability: [Int?]
        }
        var daily: Daily
        var hourly: Hourly
    }

    /// (highest WMO weather code, description)
    private static let descriptions: [(Int, String)] = [
        (0, "giedra"), (2, "mažai debesų"), (3, "debesuota"), (48, "rūkas"),
        (57, "dulksna"), (67, "lietus"), (77, "sniegas"), (82, "protarpiais lyja"),
        (86, "snygis"), (99, "perkūnija"),
    ]

    static func load() async -> Weather? {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(Response.self, from: data),
              let high = response.daily.temperature_2m_max.first,
              let low = response.daily.temperature_2m_min.first,
              let code = response.daily.weather_code.first else { return nil }

        let min = Int(low.rounded()), max = Int(high.rounded())
        var line = "Vilniuje \(min)…\(max) °C, " + (descriptions.first { code <= $0.0 }?.1 ?? "")
        let rainFrom = zip(response.hourly.time, response.hourly.precipitation_probability)
            .map { (String($0.0.suffix(5)), $0.1 ?? 0) }
            .first { $0.0 >= "07:00" && $0.0 <= "22:00" && $0.1 >= 50 }?.0
        if let rainFrom { line += ", krituliai nuo \(rainFrom)" }
        if let wind = response.daily.wind_speed_10m_max.first, wind >= 40 {
            line += ", vėjas iki \(Int(wind.rounded())) km/h"
        }
        return Weather(min: min, max: max, text: line + ".")
    }
}
