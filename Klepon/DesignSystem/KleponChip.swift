import SwiftUI

struct KleponChip: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
            }

            Text(title)
                .font(KleponTypography.chip)
        }
        .foregroundStyle(KleponColor.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(KleponColor.chipBackground))
    }
}
