import SwiftUI

struct KleponActionButton: View {
    enum Tone {
        case primary
        case secondary
    }

    let title: String
    var systemImage: String? = nil
    var tone: Tone = .primary
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }

                Text(title)
                    .font(KleponTypography.bodySecondary.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(backgroundColor)
            )
            .foregroundStyle(foregroundColor)
        }
        .kleponInteractiveButtonStyle()
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) && tone == .primary ? 0.85 : 1)
    }

    private var backgroundColor: Color {
        switch tone {
        case .primary:
            return KleponColor.accent
        case .secondary:
            return KleponColor.surface
        }
    }

    private var foregroundColor: Color {
        switch tone {
        case .primary:
            return .white
        case .secondary:
            return KleponColor.textPrimary
        }
    }
}
