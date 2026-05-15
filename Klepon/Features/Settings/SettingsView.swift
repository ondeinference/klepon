import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var recentSearchStore: RecentSearchStore
    @EnvironmentObject private var guideEngine: OndeGuideEngine

    private var versionString: String {
        let version =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                KleponCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Private guide")
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

                        KleponActionButton(
                            title: guideEngine.availability.actionTitle,
                            systemImage: guideEngine.availability == .ready
                                ? "checkmark.circle.fill" : "arrow.down.circle",
                            isLoading: guideEngine.availability.isBusy,
                            isDisabled: guideEngine.availability == .ready
                        ) {
                            Task {
                                await guideEngine.prepareIfNeeded(
                                    forceReload: guideEngine.availability.isFailure)
                            }
                        }

                        if guideEngine.storageUsedDescription != "Not downloaded yet" {
                            KleponActionButton(
                                title: "Remove private guide from this device",
                                systemImage: "trash",
                                tone: .secondary
                            ) {
                                Task {
                                    await guideEngine.removePrivateGuide()
                                }
                            }
                        }
                    }
                }

                KleponCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("App info")
                            .font(KleponTypography.cardTitle)
                            .foregroundStyle(KleponColor.textPrimary)

                        KleponMetadataRow(title: "App", value: "Klepon: Taste of Indonesia")
                        KleponMetadataRow(title: "Publisher", value: "Splitfire AB")
                        KleponMetadataRow(title: "Build", value: versionString)
                    }
                }

                KleponCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Privacy")
                            .font(KleponTypography.cardTitle)
                            .foregroundStyle(KleponColor.textPrimary)

                        Text(
                            "Browseable food content is bundled with the app. Private answers use a one-time on-device guide download when you choose to enable it."
                        )
                        .font(KleponTypography.bodySecondary)
                        .foregroundStyle(KleponColor.textSecondary)
                    }
                }

                KleponCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Browsing data")
                            .font(KleponTypography.cardTitle)
                            .foregroundStyle(KleponColor.textPrimary)

                        KleponMetadataRow(
                            title: "Saved", value: "\(favoritesStore.favoriteIDs.count) items")
                        KleponMetadataRow(
                            title: "Recent searches",
                            value: "\(recentSearchStore.queries.count) items")
                        KleponMetadataRow(
                            title: "Recently viewed",
                            value: "\(appState.recentlyViewedStore.entryIDs.count) items")

                        if !recentSearchStore.queries.isEmpty {
                            KleponActionButton(title: "Clear recent searches", tone: .secondary) {
                                recentSearchStore.clear()
                            }
                        }

                        if !appState.recentlyViewedStore.entryIDs.isEmpty {
                            KleponActionButton(title: "Clear recently viewed", tone: .secondary) {
                                appState.recentlyViewedStore.clear()
                            }
                        }

                        if !favoritesStore.favoriteIDs.isEmpty {
                            KleponActionButton(title: "Clear saved list", tone: .secondary) {
                                favoritesStore.clear()
                            }
                        }
                    }
                }

                KleponCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Onboarding")
                            .font(KleponTypography.cardTitle)
                            .foregroundStyle(KleponColor.textPrimary)

                        Text(
                            "If you want to see Klepon’s welcome and privacy intro again, you can show it on the next launch path."
                        )
                        .font(KleponTypography.bodySecondary)
                        .foregroundStyle(KleponColor.textSecondary)

                        KleponActionButton(title: "Show welcome again", tone: .secondary) {
                            appState.hasCompletedOnboarding = false
                            #if !os(tvOS)
                                dismiss()
                            #endif
                        }
                    }
                }

                KleponCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Technology")
                            .font(KleponTypography.cardTitle)
                            .foregroundStyle(KleponColor.textPrimary)

                        Text(
                            "Klepon’s private answer layer is powered on-device by Onde Inference. The technology stays in the background so the product can feel like a guide first."
                        )
                        .font(KleponTypography.bodySecondary)
                        .foregroundStyle(KleponColor.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(KleponColor.background.ignoresSafeArea())
        .navigationTitle("Settings")
        #if !os(tvOS)
            .toolbar {
                ToolbarItem(placement: .kleponPrimaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .tint(KleponColor.accent)
                }
            }
        #endif
    }
}
