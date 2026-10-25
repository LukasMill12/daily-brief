import SwiftUI

/// One story opened from the index: the headline and summary as a single large paragraph.
struct StoryView: View {
    var detail: Detail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(detail.label)
                    Spacer()
                    Button("CLOSE") { dismiss() }
                }
                .font(Theme.helvetica(11))
                .tracking(0.5)
                .foregroundStyle(Theme.accent)
                .padding(.bottom, 24)

                Text(detail.title)
                    .font(Theme.helvetica(30, medium: true))
                    .tracking(-1)
                    .foregroundStyle(Theme.text)
                    .padding(.bottom, 14)

                Text(detail.body)
                    .font(Theme.helvetica(21))
                    .tracking(-0.5)
                    .foregroundStyle(Theme.text)
                    .padding(.bottom, 18)

                if !detail.meta.isEmpty {
                    Text(detail.meta.uppercased())
                        .font(Theme.helvetica(11))
                        .tracking(0.4)
                        .foregroundStyle(Theme.accent)
                        .padding(.bottom, 10)
                }

                ForEach(detail.sources, id: \.self) { source in
                    if let url = URL(string: source.url) {
                        Link(destination: url) {
                            Text("\(source.name.uppercased()) ↗\u{FE0E}")
                                .font(Theme.helvetica(11))
                                .tracking(0.4)
                                .foregroundStyle(Theme.accent)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(18)
        }
        .background(Theme.background.ignoresSafeArea())
        .presentationBackground(Theme.background)
    }
}
