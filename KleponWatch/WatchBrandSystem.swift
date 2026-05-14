import SwiftUI

enum WatchKleponTypography {
    static let heroTitle = Font.system(size: 22, weight: .semibold, design: .serif)
    static let sectionTitle = Font.system(size: 16, weight: .semibold, design: .serif)
    static let cardTitle = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySecondary = Font.system(size: 12, weight: .regular, design: .default)
    static let caption = Font.system(size: 11, weight: .semibold, design: .default)
}

struct WatchKleponCard<Content: View>: View {
    let padding: CGFloat
    @ViewBuilder var content: Content

    init(padding: CGFloat = 14, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(KleponColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(KleponColor.divider, lineWidth: 1)
            )
    }
}

struct WatchKleponSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(WatchKleponTypography.sectionTitle)
                .foregroundStyle(KleponColor.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(WatchKleponTypography.bodySecondary)
                    .foregroundStyle(KleponColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WatchKleponChip: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(title)
                .font(WatchKleponTypography.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(KleponColor.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(KleponColor.chipBackground))
    }
}

struct WatchKleponChipGrid: View {
    let items: [String]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 72), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(items, id: \.self) { item in
                WatchKleponChip(title: item)
            }
        }
    }
}

struct WatchKleponFooterCard: View {
    let message: String

    var body: some View {
        WatchKleponCard {
            Text(message)
                .font(WatchKleponTypography.bodySecondary)
                .foregroundStyle(KleponColor.textSecondary)
                .lineSpacing(2)
        }
    }
}
