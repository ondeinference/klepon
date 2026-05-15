import Combine
import Foundation
import Onde

enum PrivateGuideAvailability: Equatable {
    case notInstalled
    case downloaded
    case preparing
    case ready
    case answering
    case failed(String)

    var title: String {
        switch self {
        case .notInstalled:
            return "Private guide not ready yet"
        case .downloaded:
            return "Private guide downloaded on this iPhone"
        case .preparing:
            return "Preparing your private guide"
        case .ready:
            return "Private guide ready on this iPhone"
        case .answering:
            return "Answering privately"
        case .failed:
            return "Private guide needs attention"
        }
    }

    var detail: String {
        switch self {
        case .notInstalled:
            return
                "You can browse everything first, then add a one-time private guide download whenever you want deeper follow-up answers."
        case .downloaded:
            return
                "The private guide is already stored on this iPhone. Finish preparing it when you want faster follow-up answers in the app."
        case .preparing:
            return
                "The first run can take a while because Klepon needs to download and load the private guide locally on your iPhone."
        case .ready:
            return
                "Klepon can now answer follow-up questions privately without turning the app into a generic chat shell."
        case .answering:
            return
                "Klepon is grounding your question against the local guide and composing a concise answer."
        case .failed(let message):
            return message
        }
    }

    var actionTitle: String {
        switch self {
        case .ready:
            return "Private guide ready"
        case .failed:
            return "Try again"
        case .downloaded:
            return "Finish preparing private guide"
        default:
            return "Prepare private guide"
        }
    }

    var isBusy: Bool {
        switch self {
        case .preparing, .answering:
            return true
        default:
            return false
        }
    }

    var isFailure: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

enum OndeGuideError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "The private guide is not ready yet."
        }
    }
}

@MainActor
final class OndeGuideEngine: ObservableObject {
    @Published private(set) var availability: PrivateGuideAvailability = .notInstalled
    @Published private(set) var storageUsedDescription: String =
        OndeEnvironmentBootstrap.storageUsageDescription()

    // Lazy so the Rust/UniFFI runtime is not initialized during app-state
    // construction before the app actually needs the private guide engine.
    private var engine: OndeChatEngine?

    var estimatedDownloadDescription: String {
        OndeEnvironmentBootstrap.estimatedDownloadDescription
    }

    private func getOrCreateEngine() -> OndeChatEngine {
        if let engine {
            return engine
        }

        let newEngine = OndeChatEngine()
        engine = newEngine
        return newEngine
    }

    func prepareIfNeeded(forceReload: Bool = false) async {
        if forceReload {
            _ = await engine?.unloadModel()
            availability = .notInstalled
        }

        switch availability {
        case .ready, .preparing, .answering:
            return
        case .notInstalled, .downloaded, .failed:
            break
        }

        availability = .preparing
        OndeEnvironmentBootstrap.configureIfNeeded()

        let engine = getOrCreateEngine()

        do {
            _ = try await engine.loadGgufModel(
                config: qwen2515bConfig(),
                systemPrompt:
                    "You are Klepon, a warm and careful guide to Indonesian food. Stay grounded in the notes you are given, keep answers short, and say clearly when the guide does not have enough detail.",
                sampling: nil
            )
            availability = .ready
            refreshStorageUsage()
        } catch {
            availability = .failed(error.localizedDescription)
            refreshStorageUsage()
        }
    }

    func answer(prompt: String) async throws -> String {
        await prepareIfNeeded()

        guard case .ready = availability else {
            throw OndeGuideError.unavailable
        }

        let engine = getOrCreateEngine()

        availability = .answering
        _ = await engine.clearHistory()

        do {
            let result = try await engine.sendMessage(message: prompt)
            availability = .ready
            refreshStorageUsage()
            return result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            availability = .failed(error.localizedDescription)
            throw error
        }
    }

    func removePrivateGuide() async {
        _ = await engine?.unloadModel()
        engine = nil
        OndeEnvironmentBootstrap.clearPrivateGuideFiles()
        availability = .notInstalled
        refreshStorageUsage()
    }

    func refreshStorageUsage() {
        storageUsedDescription = OndeEnvironmentBootstrap.storageUsageDescription()

        if storageUsedDescription == "Not downloaded yet" {
            if case .downloaded = availability {
                availability = .notInstalled
            }
        } else if case .notInstalled = availability {
            availability = .downloaded
        }
    }

    func reset() {
        if case .failed = availability {
            availability = .notInstalled
        }
        refreshStorageUsage()
    }
}
