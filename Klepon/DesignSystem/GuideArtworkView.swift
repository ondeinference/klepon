import SwiftUI

struct GuideArtworkView: View {
    let entry: GuideEntry
    var height: CGFloat = 160

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: height * 0.9, height: height * 0.9)
                .offset(x: height * 0.2, y: -height * 0.15)

            Image(systemName: entry.kind.symbolName)
                .font(.system(size: height * 0.38, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .offset(x: -10, y: -6)

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.title)
                    .font(KleponTypography.cardTitle)
                    .foregroundStyle(.white)

                Text(entry.subtitle)
                    .font(KleponTypography.caption)
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(2)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var gradientColors: [Color] {
        switch entry.kind {
        case .dish:
            return [KleponColor.accentWarm, KleponColor.highlight]
        case .ingredient:
            return [KleponColor.accent, KleponColor.accentWarm]
        case .tradition:
            return [KleponColor.accent, KleponColor.highlight]
        }
    }
}
