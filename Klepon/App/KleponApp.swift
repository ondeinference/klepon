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
                #if os(iOS)
                    .preferredColorScheme(
                        UIDevice.current.userInterfaceIdiom == .pad ? nil : .light)
                #endif
        }
        #if os(macOS) || os(visionOS)
            .defaultSize(width: 1100, height: 760)
        #endif
    }
}
