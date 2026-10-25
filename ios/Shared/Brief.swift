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

    /// Briefs written before the widget headline existed get a neutral label rather than a cut-off sentence.
    var shortHeadline: String {
        if let short = widgetHeadline, !short.isEmpty { return short }
        return "Today's brief"
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
    var images: [String]?
    var id: String { headline }
}

struct Ongoing: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var update: String
    var sources: [Source]
    var images: [String]?
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
    static let url: URL = {
        #if DEBUG
        // Lets a debug build read a local test brief: launch with BRIEF_URL=file:///path/to/brief.json.
        if let override = ProcessInfo.processInfo.environment["BRIEF_URL"], let url = URL(string: override) {
            return url
        }
        #endif
        return URL(string: "https://lukasmill12.github.io/daily-brief/brief.json")!
    }()
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

    /// Downloads every story photo into the URL cache so story pages show them instantly.
    static func preloadImages(of brief: Brief) async {
        let urls = (brief.lithuania + brief.world + brief.interesting).flatMap { $0.images ?? [] }
            + brief.ongoing.flatMap { $0.images ?? [] }
        await withTaskGroup(of: Void.self) { group in
            for case let url? in urls.map(URL.init(string:)) {
                group.addTask { _ = try? await URLSession.shared.data(from: url) }
            }
        }
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
