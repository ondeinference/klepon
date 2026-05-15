import SwiftUI

struct AppRootView: View {
    private enum Tab {
        case discover
        case search
        case saved
        #if os(tvOS)
            case settings
        #endif
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

            #if os(tvOS)
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.2")
                }
                .tag(Tab.settings)
            #endif
        }
        .tint(KleponColor.accent)
        .background(KleponColor.background.ignoresSafeArea())
        #if !os(tvOS)
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
                #if os(macOS) || os(visionOS)
                    .frame(minWidth: 480, minHeight: 620)
                #endif
            }
        #endif
        .kleponOnboardingPresentation(isPresented: $showingOnboarding) {
            OnboardingView(
                onBrowseFirst: {
                    appState.completeOnboarding()
                },
                onComplete: {
                    appState.completeOnboarding()
                }
            )
            #if os(macOS) || os(visionOS)
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
        #if os(macOS) || os(visionOS)
            .frame(minWidth: 980, minHeight: 720)
        #endif
    }
}
