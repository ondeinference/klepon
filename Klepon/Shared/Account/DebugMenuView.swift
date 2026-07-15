#if DEBUG
    import SwiftUI

    struct DebugView: View {
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    #if os(tvOS)
                        TVPageHeader("Debug")
                    #endif

                    SectionHeader("Debug")

                    DebugPanelCard()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .kleponReadableContentWidth()
            }
            .background(KleponColor.background.ignoresSafeArea())
            .navigationTitle("Debug")
            #if os(tvOS)
                .toolbar(.hidden, for: .navigationBar)
            #else
                .kleponInlineNavigationTitle()
            #endif
        }
    }

    struct DebugSettingsCard: View {
        @EnvironmentObject private var accountStore: AccountStore

        var body: some View {
            NavigationLink {
                DebugView()
            } label: {
                KleponCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "ladybug.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.orange)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Debug")
                                    .font(KleponTypography.cardTitle)
                                    .foregroundStyle(KleponColor.textPrimary)

                            }

                            Spacer(minLength: 12)

                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(KleponColor.textSecondary)
                        }

                        HStack(spacing: 10) {
                            KleponChip(
                                title: accountStore.proxyEnvironment.displayName,
                                icon: "network"
                            )

                            KleponChip(
                                title: accountStore.isSignedIn ? "Session active" : "Signed out",
                                icon: accountStore.isSignedIn
                                    ? "checkmark.circle" : "xmark.circle"
                            )
                        }
                    }
                }
            }
            .kleponInteractiveButtonStyle()
        }
    }

    private struct DebugPanelCard: View {
        @EnvironmentObject private var accountStore: AccountStore

        var body: some View {
            KleponCard {
                VStack(alignment: .leading, spacing: 14) {
                    debugHeader
                    environmentPicker
                    activeEndpointRow
                    sessionRow
                    Divider()
                        .background(KleponColor.textSecondary.opacity(0.2))
                    clearSessionButton
                }
            }
        }

        private var debugHeader: some View {
            HStack(spacing: 8) {
                Image(systemName: "ladybug.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 14, weight: .semibold))
                Text("Debug")
                    .font(KleponTypography.cardTitle)
                    .foregroundStyle(KleponColor.textPrimary)
                Spacer()
                environmentBadge
            }
        }

        private var environmentBadge: some View {
            Text(accountStore.proxyEnvironment.displayName.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(environmentBadgeColor.cornerRadius(4))
        }

        private var environmentBadgeColor: Color {
            accountStore.proxyEnvironment == .development ? .orange : .green
        }

        private var environmentPicker: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Environment")
                    .font(KleponTypography.bodySecondary)
                    .foregroundStyle(KleponColor.textSecondary)

                Picker(
                    "Environment",
                    selection: Binding(
                        get: { accountStore.proxyEnvironment },
                        set: { accountStore.switchEnvironment($0) }
                    )
                ) {
                    ForEach(AccountProxyEnvironment.allCases) { environment in
                        Text(environment.displayName).tag(environment)
                    }
                }
                .pickerStyle(.segmented)
                .applySegmentedPickerStyleForPlatform()
            }
        }

        private var activeEndpointRow: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Active endpoint")
                    .font(KleponTypography.bodySecondary)
                    .foregroundStyle(KleponColor.textSecondary)
                Text(accountStore.proxyEnvironment.baseURL.absoluteString)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(environmentBadgeColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }

        private var sessionRow: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Session")
                    .font(KleponTypography.bodySecondary)
                    .foregroundStyle(KleponColor.textSecondary)
                if accountStore.isSignedIn {
                    Text(accountStore.statusTitle)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.green)
                } else {
                    Text("No active session")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(KleponColor.textSecondary)
                }
            }
        }

        private var clearSessionButton: some View {
            KleponActionButton(
                title: "Clear session & sign out",
                systemImage: "xmark.circle",
                tone: .secondary
            ) {
                Task { await accountStore.logout() }
            }
            .disabled(!accountStore.isSignedIn)
            .opacity(accountStore.isSignedIn ? 1 : 0.4)
        }
    }

    extension View {
        @ViewBuilder
        fileprivate func applySegmentedPickerStyleForPlatform() -> some View {
            #if os(macOS)
                self.colorScheme(.light)
            #else
                self
            #endif
        }
    }

    #Preview {
        NavigationStack {
            DebugView()
                .environmentObject(AccountStore())
        }
    }
#endif
