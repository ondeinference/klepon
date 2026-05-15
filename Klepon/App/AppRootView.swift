import SwiftUI

struct AppRootView: View {
    private enum Tab {
        case discover
        case search
        case saved
    }

    @EnvironmentObject private var appState: AppState

    @State private var selectedTab: Tab = .discover
    @State private var showingSettings = false
    @State private var showingOnboarding = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DiscoverView(showingSettings: $showingSettings)
            }
            .tabItem {
                Label("Discover", systemImage: "sparkles")
            }
            .tag(Tab.discover)

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(Tab.search)

            NavigationStack {
                SavedView()
            }
            .tabItem {
                Label("Saved", systemImage: "heart")
            }
            .tag(Tab.saved)
        }
        .tint(KleponColor.accent)
        .background(KleponColor.background.ignoresSafeArea())
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
            #if os(macOS)
                .frame(minWidth: 480, minHeight: 620)
            #endif
        }
        .kleponOnboardingPresentation(isPresented: $showingOnboarding) {
            OnboardingView(
                onBrowseFirst: {
                    appState.completeOnboarding()
                },
                onComplete: {
                    appState.completeOnboarding()
                }
            )
            #if os(macOS)
                .frame(minWidth: 640, minHeight: 760)
            #endif
        }
        .task {
            showingOnboarding = !appState.hasCompletedOnboarding
            appState.guideEngine.refreshStorageUsage()
        }
        .onChange(of: appState.hasCompletedOnboarding) { _, newValue in
            showingOnboarding = !newValue
        }
        #if os(macOS)
            .frame(minWidth: 980, minHeight: 720)
        #endif
    }
}
