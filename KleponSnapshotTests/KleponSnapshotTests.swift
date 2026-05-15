import SnapshotTesting
import SwiftUI
import XCTest

@testable import Klepon

@MainActor
final class KleponSnapshotTests: XCTestCase {
    override func invokeTest() {
        if ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1" {
            withSnapshotTesting(record: .all) {
                super.invokeTest()
            }
        } else {
            super.invokeTest()
        }
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testOnboardingView_defaultState() {
        let guideEngine = OndeGuideEngine()
        let view = OnboardingView(onBrowseFirst: {}, onComplete: {})
            .environmentObject(guideEngine)

        assertSnapshot(
            of: makeHostingController(view),
            as: .image(on: .iPhoneSe),
            named: "default"
        )
    }

    func testEmptyStateView() {
        let view = ZStack {
            KleponColor.background.ignoresSafeArea()

            EmptyStateView(
                title: "No saved dishes yet",
                message:
                    "When something looks delicious, save it here so you can come back later.",
                systemImage: "heart"
            )
            .padding(24)
        }

        assertSnapshot(
            of: makeHostingController(view),
            as: .image(on: .iPhoneSe),
            named: "saved-empty-state"
        )
    }

    func testGuideArtworkView() {
        let view = ZStack {
            KleponColor.background.ignoresSafeArea()

            GuideArtworkView(entry: .snapshotFixture, height: 210)
                .padding(24)
        }

        assertSnapshot(
            of: makeHostingController(view),
            as: .image(on: .iPhoneSe),
            named: "guide-artwork"
        )
    }

    private func makeHostingController<Content: View>(_ view: Content) -> UIViewController {
        let controller = UIHostingController(rootView: view.preferredColorScheme(.light))
        controller.overrideUserInterfaceStyle = .light
        controller.view.backgroundColor = UIColor(KleponColor.background)
        return controller
    }
}

extension GuideEntry {
    fileprivate static let snapshotFixture = GuideEntry(
        id: "klepon",
        kind: .dish,
        title: "Klepon",
        subtitle: "Palm sugar-filled rice cake rolled in coconut",
        summary: "A soft, sweet bite with a warm syrupy center.",
        story:
            "Klepon is a beloved Indonesian snack made from glutinous rice flour, filled with palm sugar, and coated in fresh grated coconut.",
        tasteNotes: ["Sweet", "Chewy", "Coconut"],
        highlights: ["Palm sugar center", "Fresh coconut coating"],
        region: "Java",
        aliases: ["Onde-onde kecil"],
        tags: ["Snack", "Dessert", "Traditional"],
        relatedIDs: [],
        suggestedQuestions: ["What does klepon taste like?"],
        imageName: nil,
        isFeatured: true
    )
}
