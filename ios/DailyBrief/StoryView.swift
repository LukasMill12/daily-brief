import SwiftUI

/// One story opened from the index: headline, the lead photo, the summary, and a second photo if there is one.
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
                    .padding(.bottom, 18)

                if let first = detail.images.first {
                    Photo(url: first, aspect: 3 / 2)
                        .padding(.bottom, 18)
                }

                Text(detail.body)
                    .font(Theme.helvetica(21))
                    .tracking(-0.5)
                    .foregroundStyle(Theme.text)
                    .padding(.bottom, 18)

                if detail.images.count > 1 {
                    HStack {
                        Spacer()
                        Photo(url: detail.images[1], aspect: 4 / 5)
                            .containerRelativeFrame(.horizontal) { width, _ in width / 2 - 18 }
                    }
                    .padding(.bottom, 18)
                }

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

/// A photo cropped to a fixed shape; it simply stays empty if it can't load.
private struct Photo: View {
    var url: String
    var aspect: CGFloat

    var body: some View {
        Color.white.opacity(0.04)
            .aspectRatio(aspect, contentMode: .fit)
            .overlay {
                AsyncImage(url: URL(string: url)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.clear
                }
            }
            .clipped()
    }
}
