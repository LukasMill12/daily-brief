import SwiftUI

/// Every past brief as one line: weekday and date, then that day's widget label.
struct ArchiveView: View {
    var current: String?
    var pick: (BriefLoader.ArchiveDay) -> Void
    @State private var days: [BriefLoader.ArchiveDay]?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("ARCHIVE")
                    Spacer()
                    Button("CLOSE") { dismiss() }
                }
                .font(Theme.helvetica(11))
                .tracking(0.5)
                .foregroundStyle(Theme.accent)
                .padding(.bottom, 28)

                if let days {
                    ForEach(days) { day in
                        Button { pick(day) } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 16) {
                                Text(Self.dateLabel(day.date))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 64, alignment: .leading)
                                Text(day.label.uppercased())
                                    .foregroundStyle(day.date == current ? Theme.accent : Theme.text)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .font(Theme.helvetica(11))
                            .tracking(0.3)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("LOADING").font(Theme.helvetica(11)).tracking(0.5).foregroundStyle(Theme.accent)
                }
            }
            .padding(18)
        }
        .background(Theme.background.ignoresSafeArea())
        .presentationBackground(Theme.background)
        .task { days = await BriefLoader.loadArchiveIndex() }
    }

    /// "SK 25.10"
    private static func dateLabel(_ date: String) -> String {
        let parts = date.split(separator: "-")
        guard parts.count == 3, let day = DateFormatter.archiveDay.date(from: date) else { return date }
        let weekday = ["SK", "PR", "AN", "TR", "KT", "PN", "ŠT"][Calendar(identifier: .gregorian).component(.weekday, from: day) - 1]
        return "\(weekday) \(parts[2]).\(parts[1])"
    }
}

private extension DateFormatter {
    static let archiveDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Vilnius")
        return formatter
    }()
}
