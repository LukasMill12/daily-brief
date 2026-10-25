import SwiftUI

/// One story opened from the index: headline, summary and sources, then its photos.
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

                // Photos close the page: centred, narrower than the text, with generous space around them.
                VStack(spacing: 56) {
                    ForEach(detail.images, id: \.self) { url in
                        Photo(url: url)
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.62 }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, detail.images.isEmpty ? 0 : 64)
                .padding(.bottom, 40)
            }
            .padding(18)
        }
        .background(Theme.background.ignoresSafeArea())
        .presentationBackground(Theme.background)
    }
}

/// A photo at its own proportions; a faint placeholder holds its place until it loads.
private struct Photo: View {
    var url: String

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit()
            } else {
                Color.white.opacity(0.04).aspectRatio(4 / 3, contentMode: .fit)
            }
        }
    }
}
