import SwiftUI

@main
struct KleponApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appState)
                .environmentObject(appState.favoritesStore)
                .environmentObject(appState.recentSearchStore)
                .environmentObject(appState.recentlyViewedStore)
                .environmentObject(appState.guideEngine)
                .preferredColorScheme(.light)
        }
    }
}
