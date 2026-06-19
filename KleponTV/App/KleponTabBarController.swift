import SwiftUI
import UIKit

@MainActor
final class KleponTabBarController: UITabBarController {

    private let appState: AppState
    private var shouldGiveFocusToSelectedViewController = false

    init(appState: AppState) {
        self.appState = appState
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [
            makeTab(
                title: "Discover",
                imageName: "sparkles",
                viewController: makeDiscoverViewController()
            ),
            makeTab(
                title: "Search",
                imageName: "magnifyingglass",
                viewController: makeSearchViewController()
            ),
            makeTab(
                title: "Saved",
                imageName: "heart",
                viewController: makeSavedViewController()
            ),
            makeTab(
                title: "Settings",
                imageName: "gearshape.2",
                viewController: makeSettingsViewController()
            ),
        ]
    }

    // MARK: - Focus engine

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        guard let selectedViewController, shouldGiveFocusToSelectedViewController else {
            return super.preferredFocusEnvironments
        }
        shouldGiveFocusToSelectedViewController = false
        return [selectedViewController]
    }

    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        if let nextFocusedView = context.nextFocusedView,
            !nextFocusedView.isDescendant(of: tabBar),
            let previouslyFocusedView = context.previouslyFocusedView,
            previouslyFocusedView.isDescendant(of: tabBar)
        {
            shouldGiveFocusToSelectedViewController = true
            setNeedsFocusUpdate()
            updateFocusIfNeeded()
            return false
        }
        shouldGiveFocusToSelectedViewController = false
        return true
    }

    // MARK: - Top Shelf routing

    func handle(url: URL) {
        guard let route = TopShelfRoute(url: url, repository: appState.contentRepository) else {
            return
        }

        selectedIndex = 0
        dismissPresentedContentIfNeeded { [weak self] in
            self?.present(route: route)
        }
    }

    private func dismissPresentedContentIfNeeded(completion: @escaping () -> Void) {
        if let activePresentedViewController = selectedViewController?.presentedViewController
            ?? presentedViewController
        {
            activePresentedViewController.dismiss(animated: false, completion: completion)
        } else {
            completion()
        }
    }

    private func present(route: TopShelfRoute) {
        switch route {
        case .entry(let entry):
            let detailView = NavigationStack {
                GuideDetailView(entry: entry)
            }
            .withKleponEnvironment(appState: appState)
            let hostingController = UIHostingController(rootView: detailView)
            hostingController.modalPresentationStyle = .fullScreen
            presentationSourceViewController.present(hostingController, animated: true)
        case .ask(let entry):
            let askView = NavigationStack {
                AskSheetView(entry: entry, initialQuestion: nil)
            }
            .withKleponEnvironment(appState: appState)
            let hostingController = UIHostingController(rootView: askView)
            hostingController.modalPresentationStyle = .fullScreen
            presentationSourceViewController.present(hostingController, animated: true)
        }
    }

    private var presentationSourceViewController: UIViewController {
        selectedViewController ?? self
    }

    // MARK: - Tab factories

    private func makeTab(
        title: String,
        imageName: String,
        viewController: UIViewController
    ) -> UIViewController {
        viewController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: imageName),
            selectedImage: UIImage(systemName: "\(imageName).fill")
        )
        viewController.tabBarItem.accessibilityIdentifier = title.lowercased()
        return viewController
    }

    private func makeDiscoverViewController() -> UIViewController {
        // DiscoverView on tvOS uses a constant binding for showingSettings (settings is a tab)
        let view = DiscoverView(showingSettings: .constant(false))
            .withKleponEnvironment(appState: appState)
        return UIHostingController(rootView: view)
    }

    private func makeSearchViewController() -> UIViewController {
        let view = SearchView()
            .withKleponEnvironment(appState: appState)
        return UIHostingController(rootView: view)
    }

    private func makeSavedViewController() -> UIViewController {
        let view = SavedView()
            .withKleponEnvironment(appState: appState)
        return UIHostingController(rootView: view)
    }

    private func makeSettingsViewController() -> UIViewController {
        let view = SettingsView()
            .withKleponEnvironment(appState: appState)
        return UIHostingController(rootView: view)
    }
}

private enum TopShelfRoute {
    case entry(GuideEntry)
    case ask(GuideEntry)

    init?(url: URL, repository: ContentRepository) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.scheme?.lowercased() == "klepon",
            let host = components.host?.lowercased(),
            let entryID = components.queryItems?.first(where: { $0.name == "id" })?.value,
            let entry = repository.entry(id: entryID)
        else {
            return nil
        }

        switch host {
        case "entry":
            self = .entry(entry)
        case "ask":
            self = .ask(entry)
        default:
            return nil
        }
    }
}

// MARK: - Environment injection helper

extension View {
    fileprivate func withKleponEnvironment(appState: AppState) -> some View {
        self
            .environmentObject(appState)
            .environmentObject(appState.favoritesStore)
            .environmentObject(appState.recentSearchStore)
            .environmentObject(appState.recentlyViewedStore)
            .environmentObject(appState.guideEngine)
            .environmentObject(appState.accountStore)
    }
}
