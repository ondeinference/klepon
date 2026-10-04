import Combine
import Ed
import Foundation

#if os(tvOS)
    import Darwin
#endif

enum PrivateGuideAvailability: Equatable {
    case notInstalled
    case downloaded
    case preparing
    case ready
    case answering
    case failed(String)
    case unsupported(String)

    var title: String {
        switch self {
        case .notInstalled:
            return "Private guide not ready yet"
        case .downloaded:
            return "Private guide downloaded on this device"
        case .preparing:
            return "Preparing your private guide"
        case .ready:
            return "Private guide ready on this device"
        case .answering:
            return "Answering privately"
        case .failed:
            return "Private guide needs attention"
        case .unsupported:
            return "Private guide not available on this device"
        }
    }

    var detail: String {
        switch self {
        case .notInstalled:
            return
                "You can browse everything first, then add a one-time private guide download whenever you want deeper follow-up answers."
        case .downloaded:
            return
                "The private guide is already stored on this device. Finish preparing it when you want faster follow-up answers in the app."
        case .preparing:
            return
                "The first run can take a while because Klepon needs to download and load the private guide locally on your device."
        case .ready:
            return
                "Klepon can now answer follow-up questions privately without turning the app into a generic chat shell."
        case .answering:
            return
                "Klepon is grounding your question against the local guide and composing a concise answer."
        case .failed(let message):
            return message
        case .unsupported(let reason):
            return reason
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
        case .unsupported:
            return "Not available"
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

    var isUnsupported: Bool {
        if case .unsupported = self {
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

/// Abstraction over the on-device guide engine. Depending on this protocol
/// instead of the concrete `OndeGuideEngine` lets higher-level services such as
/// `GuideAnswerService` be unit-tested with a fake, without spinning up the
/// Rust/UniFFI inference runtime.
protocol GuideAnswering: AnyObject {
    func answer(prompt: String) async throws -> String
}

#if os(tvOS)
    /// Check if this Apple TV has the Metal capabilities needed for on-device inference.
    /// AppleTV14,1 (Apple TV 4K 3rd gen, A15) is the minimum. Older chips (A10X, A12)
    /// lack simdgroup_matrix support and crash at shader compilation.
    func kleponDeviceSupportsInference() -> Bool {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let identifier = String(cString: machine)

        guard identifier.hasPrefix("AppleTV") else { return false }
        let numericPart = identifier.dropFirst("AppleTV".count)
        guard let commaIndex = numericPart.firstIndex(of: ",") else { return false }
        guard let generation = Int(numericPart[numericPart.startIndex..<commaIndex]) else {
            return false
        }
        return generation >= 14
    }
#endif

@MainActor
final class OndeGuideEngine: ObservableObject, GuideAnswering {
    @Published private(set) var availability: PrivateGuideAvailability = .notInstalled
    @Published private(set) var storageUsedDescription: String =
        OndeEnvironmentBootstrap.storageUsageDescription()

    // Lazy so the Rust/UniFFI runtime is not initialized during app-state
    // construction before the app actually needs the private guide engine.
    private var engine: EdAgent?

    var estimatedDownloadDescription: String {
        OndeEnvironmentBootstrap.estimatedDownloadDescription
    }

    private func getOrCreateEngine() -> EdAgent {
        if let engine {
            return engine
        }

        let newEngine = EdAgent()
        engine = newEngine
        return newEngine
    }

    func prepareIfNeeded(forceReload: Bool = false) async {
        if forceReload {
            _ = await engine?.unload()
            availability = .notInstalled
        }

        switch availability {
        case .ready, .preparing, .answering, .unsupported:
            return
        case .notInstalled, .downloaded, .failed:
            break
        }

        #if os(tvOS)
            if !kleponDeviceSupportsInference() {
                availability = .unsupported(
                    "The private guide requires Apple TV 4K 3rd generation (2022) or newer. "
                        + "Older models don't have the hardware needed to run on-device inference."
                )
                return
            }
        #endif

        availability = .preparing
        OndeEnvironmentBootstrap.configureIfNeeded()

        let engine = getOrCreateEngine()

        do {
            guard
                let appId = Bundle.main.object(forInfoDictionaryKey: "OndeAppId") as? String,
                let appSecret = Bundle.main.object(forInfoDictionaryKey: "OndeAppSecret")
                    as? String,
                !appId.isEmpty,
                !appSecret.isEmpty
            else {
                availability = .failed(
                    "Onde credentials not configured. See Configs/Secrets.xcconfig.")
                return
            }

            _ = try await engine.loadAssignedModel(
                environment: .production,
                appID: appId,
                appSecret: appSecret,
                systemPrompt:
                    "You are Klepon, a warm and careful guide to Indonesian food. Stay grounded in the notes you are given, keep answers short, and say clearly when the guide does not have enough detail."
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
            let result = try await engine.send(prompt)
            availability = .ready
            refreshStorageUsage()
            return result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            availability = .failed(error.localizedDescription)
            throw error
        }
    }

    func removePrivateGuide() async {
        _ = await engine?.unload()
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
