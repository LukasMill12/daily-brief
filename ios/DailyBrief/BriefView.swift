import SwiftUI

/// One tappable line in the index and what it opens into.
struct Detail: Identifiable {
    var label: String
    var line: String
    var title: String
    var body: String
    var meta: String
    var sources: [Source]
    var images: [String] = []
    var id: String { label + line }
}

struct BriefView: View {
    @State private var today: Brief? = BriefLoader.cached()
    /// A past day picked from the archive; nil shows today.
    @State private var past: Brief?
    @State private var showArchive = false
    @State private var open: Detail?
    /// The phone's own forecast; kept across refreshes so the temperature never blinks out.
    @State private var liveWeather: Weather?
    private let decor = Decor.current
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            if let brief = past ?? today {
                content(brief)
                    .id(brief.date)  // a new day starts at the top
            } else {
                Text("LOADING")
                    .font(Theme.helvetica(11))
                    .tracking(0.5)
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity, minHeight: 400)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .refreshable { await reload() }
        .task { await reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await reload() } }
        }
        .sheet(item: $open) { StoryView(detail: $0) }
        .sheet(isPresented: $showArchive) {
            ArchiveView(current: (past ?? today)?.date) { day in
                showArchive = false
                Task { await show(day) }
            }
        }
    }

    /// Shows a past day, or today again when `day` is today's date.
    private func show(_ day: BriefLoader.ArchiveDay) async {
        if day.date == today?.date {
            past = nil
        } else if let brief = await BriefLoader.loadArchived(day.date) {
            past = brief
            Task.detached { await BriefLoader.preloadImages(of: brief) }
        }
    }

    /// Opening the app in any way (icon, widget, notification) counts as reading today's brief.
    private func reload() async {
        async let fresh = BriefLoader.load()
        async let weather = WeatherLoader.load()
        if let fresh = await fresh { today = fresh }
        if let weather = await weather { liveWeather = weather }  // a failed fetch keeps the last forecast
        if let brief = today {
            SeenState.markSeen(brief)
            Task.detached { await BriefLoader.preloadImages(of: brief) }
        }
        _ = await BriefLoader.loadArchiveIndex()  // keeps the archive list ready to open instantly
    }

    private func content(_ brief: Brief) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if past != nil {
                    Button("← TODAY") { past = nil }
                } else {
                    Text("THE BRIEF")
                        #if DEBUG
                        .onLongPressGesture { DailyNotification.sendTest() }  // test the notification; lock the phone
                        #endif
                }
                Spacer()
                // Tapping the date opens the archive.
                Button(brief.date.split(separator: "-").reversed().joined(separator: ".")) { showArchive = true }
                Spacer()
                Text(weather(brief).map { "\($0.min)…\($0.max)°" } ?? " ")
            }
            .font(Theme.helvetica(11))
            .tracking(0.5)
            .foregroundStyle(decor == .blueCover || decor == .grainGlow ? .white : Theme.accent)
            .padding(.bottom, 18 + decor.contentInsets.top)

            ForEach(brief.headsUp, id: \.self) { note in
                Text(note.uppercased())
                    .font(Theme.helvetica(11))
                    .tracking(0.3)
                    .foregroundStyle(Theme.text)
                    .padding(.bottom, 6)
            }

            if let lead = brief.lead {
                Button { open = detail(lead, label: label(for: brief.leadSection)) } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TOP STORY")
                            .font(Theme.helvetica(11))
                            .tracking(0.5)
                            .foregroundStyle(Theme.accent)
                        Text(lead.headline)
                            .font(Theme.helvetica(30, medium: true))
                            .tracking(-1)
                            .foregroundStyle(Theme.text)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, brief.headsUp.isEmpty ? 0 : 12)
                .padding(.bottom, 28)
            }

            LazyVGrid(columns: [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)],
                      alignment: .leading, spacing: 22) {
                ForEach(columns(brief), id: \.0) { label, details in
                    if !details.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(label)
                                .foregroundStyle(Theme.accent)
                                .padding(.bottom, 2)
                            ForEach(details) { item in
                                Button { open = item } label: {
                                    Text(item.line.uppercased())
                                        .foregroundStyle(Theme.text)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .font(Theme.helvetica(11))
                        .tracking(0.3)
                    }
                }
            }

            footer(brief)
                .padding(.top, 36)
        }
        .padding(.leading, decor.contentInsets.leading)
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 32 + decor.contentInsets.bottom)
        .background(alignment: .top) { DecorView(decor: decor, brief: brief) }
    }

    private func footer(_ brief: Brief) -> some View {
        HStack(alignment: .center, spacing: 12) {
            footerLines(brief)
            Spacer(minLength: 0)
            if decor == .liquidFigures { FooterFigures() }
        }
    }

    private func footerLines(_ brief: Brief) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let forecast = weather(brief) {
                Text(forecast.text.uppercased())
            }
            Text("\(Theme.coordinates) · \(brief.stats?.itemsRead ?? 0) HEADLINES READ")
            // The phone fetches weather itself, so the cloud's weather problems don't matter here.
            let problems = (brief.stats?.feedProblems ?? []).map { $0.components(separatedBy: ":")[0] }
                .filter { $0 != "weather" }
            if !problems.isEmpty {
                Text((brief.date == today?.date ? "NOT WORKING TODAY: " : "NOT WORKING THAT DAY: ") + problems.joined(separator: ", ").uppercased())
            }
        }
        .font(Theme.helvetica(11))
        .tracking(0.3)
        .foregroundStyle(decor == .issueGrain ? Color.white.opacity(0.8) : Theme.accent.opacity(0.7))
    }

    // MARK: - Content shaping

    private func columns(_ brief: Brief) -> [(String, [Detail])] {
        let lead = brief.lead
        func stories(_ list: [Story], _ label: String) -> [Detail] {
            list.filter { $0 != lead }.map { detail($0, label: label) }
        }
        let ongoing = brief.ongoing.map {
            Detail(label: "ONGOING", line: $0.title, title: $0.title, body: $0.update, meta: "", sources: $0.sources,
                   images: $0.images ?? [])
        }
        let vilnius = brief.events.filter { $0.scope == "vilnius" }.map(eventDetail)
        let worldEvents = brief.events.filter { $0.scope != "vilnius" }.map(eventDetail)
        return [
            ("LIETUVA", stories(brief.lithuania, "LIETUVA")),
            ("WORLD", stories(brief.world, "WORLD")),
            ("ONGOING", ongoing),
            ("INTERESTING", stories(brief.interesting, "INTERESTING")),
            ("VILNIUS", vilnius),
            ("WORLD EVENTS", worldEvents),
        ]
    }

    private func eventDetail(_ event: Event) -> Detail {
        Detail(label: event.scope == "vilnius" ? "VILNIUS" : "WORLD EVENTS",
               line: "\(event.title) — \(event.when)", title: event.title,
               body: [event.when, event.where].filter { !$0.isEmpty }.joined(separator: ", "),
               meta: "", sources: event.sources)
    }

    private func detail(_ story: Story, label: String) -> Detail {
        Detail(label: label, line: story.headline, title: story.headline, body: story.summary,
               meta: story.why, sources: story.sources, images: story.images ?? [])
    }

    /// The phone's current forecast, or the brief's 09:00 forecast as a fallback.
    private func weather(_ brief: Brief) -> Weather? {
        brief.date == today?.date ? (liveWeather ?? brief.weather) : brief.weather
    }

    private func label(for section: String?) -> String {
        section == "world" ? "WORLD" : "LIETUVA"
    }
}
