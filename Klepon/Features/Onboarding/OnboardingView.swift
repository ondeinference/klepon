import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var guideEngine: OndeGuideEngine

    let onBrowseFirst: () -> Void
    let onComplete: () -> Void

    private var privateGuideButtonTitle: String {
        switch guideEngine.availability {
        case .ready:
            return "Private guide ready"
        case .downloaded:
            return "Finish preparing private guide"
        case .failed:
            return "Try private guide again"
        default:
            return "Add private guide"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 24)

                Text("Klepon")
                    .font(KleponTypography.heroTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text("Taste of Indonesia")
                    .font(KleponTypography.screenTitle)
                    .foregroundStyle(KleponColor.accentWarm)

                Text("A warm pocket guide to Indonesian dishes, ingredients, and food traditions.")
                    .font(KleponTypography.body)
                    .foregroundStyle(KleponColor.textSecondary)

                KleponCard {
                    onboardingPoint(
                        title: "Curated before clever",
                        detail:
                            "Browse thoughtful dishes and food notes first. The AI layer stays in the background.",
                        systemImage: "fork.knife"
                    )
                }

                KleponCard {
                    onboardingPoint(
                        title: "Private on your device",
                        detail:
                            "Private answers use a one-time on-device guide download. You can browse first and add it later.",
                        systemImage: "lock"
                    )
                }

                KleponCard {
                    onboardingPoint(
                        title: "Made to feel calm",
                        detail:
                            "No accounts, no noisy feeds, and no generic chatbot shell. Just a clean guide you can keep close.",
                        systemImage: "sparkles"
                    )
                }

                KleponCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Private guide status")
                            .font(KleponTypography.cardTitle)
                            .foregroundStyle(KleponColor.textPrimary)

                        Text(guideEngine.availability.title)
                            .font(KleponTypography.bodySecondary)
                            .foregroundStyle(
                                guideEngine.availability.isFailure
                                    ? KleponColor.highlight : KleponColor.textSecondary)

                        Text(guideEngine.availability.detail)
                            .font(KleponTypography.caption)
                            .foregroundStyle(KleponColor.textSecondary)

                        HStack(spacing: 10) {
                            KleponChip(
                                title: guideEngine.estimatedDownloadDescription,
                                icon: "arrow.down.circle")
                            KleponChip(
                                title: guideEngine.storageUsedDescription, icon: "internaldrive")
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 180)
        }
        .background(KleponColor.background.ignoresSafeArea())
        #if os(macOS)
            .safeAreaInset(edge: .bottom) {
                onboardingActions
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(KleponColor.background)
            }
        #else
            .safeAreaInset(edge: .bottom) {
                onboardingActions
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(.ultraThinMaterial)
            }
        #endif
    }

    private var onboardingActions: some View {
        VStack(spacing: 12) {
            KleponActionButton(
                title: privateGuideButtonTitle,
                systemImage: "lock",
                isLoading: guideEngine.availability.isBusy,
                isDisabled: guideEngine.availability == .ready
            ) {
                Task {
                    await guideEngine.prepareIfNeeded(
                        forceReload: guideEngine.availability.isFailure)
                    if guideEngine.availability == .ready {
                        onComplete()
                    }
                }
            }

            KleponActionButton(title: "Browse first", tone: .secondary) {
                onBrowseFirst()
            }
        }
    }

    private func onboardingPoint(title: String, detail: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(KleponColor.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(KleponTypography.cardTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text(detail)
                    .font(KleponTypography.bodySecondary)
                    .foregroundStyle(KleponColor.textSecondary)
            }
        }
    }
}
