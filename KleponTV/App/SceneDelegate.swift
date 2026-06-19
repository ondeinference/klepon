import SwiftUI
import UIKit

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    static let configurationName = "Default Configuration"

    var window: UIWindow?

    private let appState = AppState()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let launchURL = connectionOptions.urlContexts.first?.url
        let tabBarController = KleponTabBarController(appState: appState)
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        self.window = window

        if let launchURL {
            tabBarController.handle(url: launchURL)
        }

        Task {
            appState.guideEngine.refreshStorageUsage()
            await appState.accountStore.restoreSessionIfNeeded()
            if launchURL == nil, !appState.hasCompletedOnboarding {
                await showOnboarding(from: tabBarController)
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url,
            let tabBarController = window?.rootViewController as? KleponTabBarController
        else {
            return
        }

        tabBarController.handle(url: url)
    }

    private func showOnboarding(from presenter: UIViewController) async {
        let onboardingView = OnboardingView(
            onBrowseFirst: { [weak self] in self?.appState.completeOnboarding() },
            onComplete: { [weak self] in self?.appState.completeOnboarding() }
        )
        .environmentObject(appState)
        .environmentObject(appState.favoritesStore)
        .environmentObject(appState.recentSearchStore)
        .environmentObject(appState.recentlyViewedStore)
        .environmentObject(appState.guideEngine)
        .environmentObject(appState.accountStore)

        let hostingController = UIHostingController(rootView: onboardingView)
        hostingController.modalPresentationStyle = .fullScreen
        presenter.present(hostingController, animated: true)
    }
}
