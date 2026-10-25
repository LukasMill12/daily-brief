import SwiftUI

/// One tappable line in the index and what it opens into.
struct Detail: Identifiable {
    var label: String
    var line: String
    var title: String
    var body: String
    var meta: String
    var sources: [Source]
    var id: String { label + line }
}

struct BriefView: View {
    @State private var brief: Brief? = BriefLoader.cached()
    @State private var open: Detail?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            if let brief {
                content(brief)
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
    }

    private func reload() async {
        if let fresh = await BriefLoader.load() { brief = fresh }
    }

    private func content(_ brief: Brief) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("THE BRIEF")
                Spacer()
                Text(brief.date.split(separator: "-").reversed().joined(separator: "."))
                Spacer()
                Text(brief.weather.map { "\($0.min)…\($0.max)°" } ?? " ")
            }
            .font(Theme.helvetica(11))
            .tracking(0.5)
            .foregroundStyle(Theme.accent)
            .padding(.bottom, 18)

            ForEach(brief.headsUp, id: \.self) { note in
                Text(note.uppercased())
                    .font(Theme.helvetica(11))
                    .tracking(0.3)
                    .foregroundStyle(Theme.text)
                    .padding(.bottom, 6)
            }

            if let lead = brief.lead {
                Button { open = detail(lead, label: label(for: brief.leadSection)) } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        (Text(headline(lead)).foregroundStyle(Theme.text)
                            + Text(" " + lead.summary).foregroundStyle(Theme.muted))
                            .font(Theme.helvetica(22, medium: true))
                            .tracking(-0.7)
                            .multilineTextAlignment(.leading)
                        Text(meta(lead))
                            .font(Theme.helvetica(11))
                            .tracking(0.4)
                            .foregroundStyle(Theme.accent)
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
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 32)
    }

    private func footer(_ brief: Brief) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let weather = brief.weather {
                Text(weather.text.uppercased())
            }
            Text("\(Theme.coordinates) · \(brief.stats?.itemsRead ?? 0) HEADLINES READ")
            if let problems = brief.stats?.feedProblems, !problems.isEmpty {
                Text("NOT WORKING TODAY: " + problems.map { $0.components(separatedBy: ":")[0] }.joined(separator: ", ").uppercased())
            }
        }
        .font(Theme.helvetica(11))
        .tracking(0.3)
        .foregroundStyle(Theme.accent.opacity(0.7))
    }

    // MARK: - Content shaping

    private func columns(_ brief: Brief) -> [(String, [Detail])] {
        let lead = brief.lead
        func stories(_ list: [Story], _ label: String) -> [Detail] {
            list.filter { $0 != lead }.map { detail($0, label: label) }
        }
        let ongoing = brief.ongoing.map {
            Detail(label: "ONGOING", line: $0.title, title: $0.title, body: $0.update, meta: "", sources: $0.sources)
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
               meta: story.why, sources: story.sources)
    }

    private func label(for section: String?) -> String {
        section == "world" ? "WORLD" : "LIETUVA"
    }

    private func headline(_ story: Story) -> String {
        let headline = story.headline.trimmingCharacters(in: .whitespaces)
        return headline.last.map { ".!?".contains($0) } == true ? headline : headline + "."
    }

    private func meta(_ story: Story) -> String {
        let names = story.sources.map(\.name).joined(separator: " · ")
        return [names, story.why].filter { !$0.isEmpty }.joined(separator: " — ").uppercased()
    }
}
