import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(KleponTypography.sectionTitle)
                .foregroundStyle(KleponColor.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(KleponTypography.bodySecondary)
                    .foregroundStyle(KleponColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TVPageHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(KleponTypography.screenTitle)
            .foregroundStyle(KleponColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
            .padding(.bottom, 8)
    }
}
