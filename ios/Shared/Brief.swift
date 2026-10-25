import Foundation

/// Mirrors docs/brief.json written by the generator. Newer fields are optional so older briefs still decode.
struct Brief: Codable, Equatable {
    var date: String
    var generatedAt: String?
    var weather: Weather?
    var leadSection: String?
    var widgetHeadline: String?
    var headsUp: [String]
    var lithuania: [Story]
    var world: [Story]
    var interesting: [Story]
    var events: [Event]
    var ongoing: [Ongoing]
    var quietOngoing: [String]
    var stats: Stats?

    enum CodingKeys: String, CodingKey {
        case date, weather, lithuania, world, interesting, events, ongoing, stats
        case generatedAt = "generated_at", leadSection = "lead_section", widgetHeadline = "widget_headline"
        case headsUp = "heads_up", quietOngoing = "quiet_ongoing"
    }

    /// The day's most important story: shown as the large paragraph in the app and on the widget.
    var lead: Story? {
        leadSection == "world" ? (world.first ?? lithuania.first) : (lithuania.first ?? world.first)
    }

    var shortHeadline: String {
        if let short = widgetHeadline, !short.isEmpty { return short }
        // Older briefs have no short headline: keep whole words up to what fits on the curve.
        guard let headline = lead?.headline else { return "" }
        var short = ""
        for word in headline.split(separator: " ") {
            let next = short.isEmpty ? String(word) : short + " " + word
            if next.count > 22 { break }
            short = next
        }
        return short.trimmingCharacters(in: CharacterSet(charactersIn: ",:–-"))
    }

    var storyCount: Int { lithuania.count + world.count + interesting.count + ongoing.count }

    /// "25.10"
    var dayMonth: String {
        let parts = date.split(separator: "-")
        return parts.count == 3 ? "\(parts[2]).\(parts[1])" : date
    }
}

struct Story: Codable, Equatable, Identifiable {
    var headline: String
    var summary: String
    var category: String
    var highlight: Bool
    var coverage: Int
    var why: String
    var sources: [Source]
    var id: String { headline }
}

struct Ongoing: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var update: String
    var sources: [Source]
}

struct Event: Codable, Equatable, Identifiable {
    var title: String
    var when: String
    var `where`: String
    var scope: String
    var sources: [Source]
    var id: String { title + when }
}

struct Source: Codable, Equatable, Hashable {
    var name: String
    var url: String
}

struct Weather: Codable, Equatable {
    var min: Int
    var max: Int
    var text: String
}

struct Stats: Codable, Equatable {
    var itemsRead: Int?
    var feedProblems: [String]?

    enum CodingKeys: String, CodingKey {
        case itemsRead = "items_read", feedProblems = "feed_problems"
    }
}

enum BriefLoader {
    static let url = URL(string: "https://lukasmill12.github.io/daily-brief/brief.json")!
    private static let cacheKey = "lastBrief"

    /// Fetches the latest brief, falling back to the last one that loaded.
    static func load() async -> Brief? {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        if let (data, _) = try? await URLSession.shared.data(for: request),
           let brief = try? JSONDecoder().decode(Brief.self, from: data) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            return brief
        }
        return cached()
    }

    static func cached() -> Brief? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(Brief.self, from: data)
    }
}

extension Brief {
    static let sample = Brief(
        date: "2026-10-25", weather: Weather(min: 8, max: 13, text: "Vilniuje 8…13 °C, debesuota."),
        leadSection: "lithuania", widgetHeadline: "Skolinimosi kaina kyla", headsUp: [],
        lithuania: [], world: [], interesting: [], events: [], ongoing: [], quietOngoing: []
    )
}
