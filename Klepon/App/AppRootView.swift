import SwiftUI

struct AppRootView: View {
    private enum Tab: Hashable {
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

    // iPad / macOS split-view sidebar selection
    @State private var sidebarSelection: Tab? = .discover

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var isRegularWidth: Bool { horizontalSizeClass == .regular }
    #endif

    var body: some View {
        #if os(iOS)
            if isRegularWidth {
                iPadRootView
            } else {
                iPhoneRootView
            }
        #else
            iPhoneRootView
        #endif
    }

    // MARK: – iPhone / tvOS root (TabView)

    private var iPhoneRootView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DiscoverView(showingSettings: $showingSettings)
            }
            .tabItem { Label("Discover", systemImage: "sparkles") }
            .tag(Tab.discover)

            NavigationStack {
                SearchView()
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(Tab.search)

            NavigationStack {
                SavedView()
            }
            .tabItem { Label("Saved", systemImage: "heart") }
            .tag(Tab.saved)

            #if os(tvOS)
                NavigationStack {
                    SettingsView()
                }
                .tabItem { Label("Settings", systemImage: "gearshape.2") }
                .tag(Tab.settings)
            #endif
        }
        .tint(KleponColor.accent)
        .background(KleponColor.background.ignoresSafeArea())
        #if !os(tvOS)
            .sheet(isPresented: $showingSettings) {
                NavigationStack { SettingsView() }
                    #if os(macOS) || os(visionOS)
                        .frame(minWidth: 480, minHeight: 620)
                    #endif
            }
        #endif
        .kleponOnboardingPresentation(isPresented: $showingOnboarding) {
            OnboardingView(
                onBrowseFirst: { appState.completeOnboarding() },
                onComplete: { appState.completeOnboarding() }
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

    // MARK: – iPad root (NavigationSplitView)

    #if os(iOS)
        private var iPadRootView: some View {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                iPadSidebar
                    .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
            } detail: {
                iPadDetail
            }
            .navigationSplitViewStyle(.balanced)
            .tint(KleponColor.accent)
            .sheet(isPresented: $showingSettings) {
                NavigationStack { SettingsView() }
                    .presentationDetents([.large])
            }
            .kleponOnboardingPresentation(isPresented: $showingOnboarding) {
                OnboardingView(
                    onBrowseFirst: { appState.completeOnboarding() },
                    onComplete: { appState.completeOnboarding() }
                )
            }
            .task {
                showingOnboarding = !appState.hasCompletedOnboarding
                appState.guideEngine.refreshStorageUsage()
            }
            .onChange(of: appState.hasCompletedOnboarding) { _, newValue in
                showingOnboarding = !newValue
            }
        }

        private var iPadSidebar: some View {
            List(selection: $sidebarSelection) {
                Section {
                    Label("Discover", systemImage: "sparkles")
                        .tag(Tab.discover)
                    Label("Search", systemImage: "magnifyingglass")
                        .tag(Tab.search)
                    Label("Saved", systemImage: "heart")
                        .tag(Tab.saved)
                } header: {
                    Text("Klepon")
                        .font(KleponTypography.caption)
                        .foregroundStyle(KleponColor.textSecondary)
                }
            }
            .listStyle(.sidebar)
            .background(KleponColor.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.2")
                    }
                    .tint(KleponColor.accent)
                }
            }
            .navigationTitle("Klepon")
        }

        @ViewBuilder
        private var iPadDetail: some View {
            switch sidebarSelection ?? .discover {
            case .discover:
                NavigationStack {
                    DiscoverView(showingSettings: $showingSettings)
                }
            case .search:
                NavigationStack {
                    SearchView()
                }
            case .saved:
                NavigationStack {
                    SavedView()
                }
            }
        }
    #endif
}
