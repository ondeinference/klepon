import SwiftUI

struct KleponMetadataRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(title)
                .font(KleponTypography.caption)
                .foregroundStyle(KleponColor.accentWarm)
                .frame(width: 110, alignment: .leading)

            Text(value)
                .font(KleponTypography.bodySecondary)
                .foregroundStyle(KleponColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
