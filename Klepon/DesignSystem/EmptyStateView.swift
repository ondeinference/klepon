import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(KleponColor.accent)

            Text(title)
                .font(KleponTypography.sectionTitle)
                .foregroundStyle(KleponColor.textPrimary)

            Text(message)
                .font(KleponTypography.bodySecondary)
                .foregroundStyle(KleponColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(KleponColor.surface)
        )
    }
}
