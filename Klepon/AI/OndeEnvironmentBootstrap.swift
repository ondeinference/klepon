import Foundation

enum OndeEnvironmentBootstrap {
    struct Paths {
        let baseURL: URL
        let hfHomeURL: URL
        let hfHubCacheURL: URL
        let temporaryURL: URL
    }

    private static var didConfigure = false

    static var estimatedDownloadDescription: String {
        #if os(tvOS)
            "About 380 MB"
        #else
            "About 941 MB"
        #endif
    }

    static func configureIfNeeded() {
        guard !didConfigure else { return }

        guard let paths = paths() else {
            NSLog(
                "[OndeEnvironmentBootstrap] ERROR: could not find any writable directory for HF cache"
            )
            return
        }

        NSLog("[OndeEnvironmentBootstrap] Using base directory: %@", paths.baseURL.path)

        setenv("HF_HOME", paths.hfHomeURL.path, 1)
        setenv("HF_HUB_CACHE", paths.hfHubCacheURL.path, 1)
        setenv("HUGGINGFACE_HUB_CACHE", paths.hfHubCacheURL.path, 1)
        setenv("TMPDIR", paths.temporaryURL.path, 1)

        NSLog("[OndeEnvironmentBootstrap] HF_HOME=%@", paths.hfHomeURL.path)
        NSLog("[OndeEnvironmentBootstrap] HF_HUB_CACHE=%@", paths.hfHubCacheURL.path)

        didConfigure = true
    }

    static func storageUsageDescription() -> String {
        guard let paths = paths() else { return "Not available" }
        let byteCount = directorySize(at: paths.baseURL)
        guard byteCount > 0 else { return "Not downloaded yet" }
        return ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }

    static func clearPrivateGuideFiles() {
        guard let paths = paths() else { return }
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: paths.baseURL)
        try? fileManager.removeItem(at: paths.temporaryURL)
        didConfigure = false
        configureIfNeeded()
    }

    // MARK: - Path resolution

    /// Resolve the best writable base directory for model storage.
    ///
    /// Priority order:
    ///   1. App Group container — persistent, shared across apps in the group.
    ///      This is the preferred location matching splitfire/pepakbasajawa.
    ///   2. Library/Caches (tvOS only) — writable but can be purged by the system.
    ///   3. Library/Application Support — persistent, app-private.
    ///   4. Temporary directory — always writable, last resort.
    ///
    /// Instead of a separate writability probe, we try to create the actual
    /// subdirectories we need (models/hub/, tmp/). If that succeeds, the path
    /// is usable.
    static func paths() -> Paths? {
        let fileManager = FileManager.default

        // 1. App Group container (highest priority — persistent + shared)
        if let appGroupURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.ondeinference.apps"
        ) {
            NSLog("[OndeEnvironmentBootstrap] App Group URL returned: %@", appGroupURL.path)

            let paths = makePaths(from: appGroupURL)
            if tryCreateDirectories(paths, label: "AppGroup") {
                return paths
            }
        } else {
            NSLog("[OndeEnvironmentBootstrap] App Group container returned nil")
        }

        // 2. Library/Application Support/OndeCache (persistent, survives app updates)
        if let appSupportURL = fileManager.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first {
            let supportBase = appSupportURL.appendingPathComponent(
                "OndeCache", isDirectory: true)
            let paths = makePaths(from: supportBase)
            if tryCreateDirectories(paths, label: "ApplicationSupport") {
                return paths
            }
        }

        // 3. Library/Caches/OndeCache (writable, but purgeable — wiped on reinstall)
        #if os(tvOS)
            if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                let cacheBase = cachesURL.appendingPathComponent("OndeCache", isDirectory: true)
                let paths = makePaths(from: cacheBase)
                if tryCreateDirectories(paths, label: "Caches") {
                    return paths
                }
            }
        #endif

        // 4. Hard fallback: temporary directory
        let fallback = fileManager.temporaryDirectory
            .appendingPathComponent("OndeCache", isDirectory: true)
        let paths = makePaths(from: fallback)
        if tryCreateDirectories(paths, label: "TempDir") {
            NSLog("[OndeEnvironmentBootstrap] Using temp fallback: %@", fallback.path)
            return paths
        }

        return nil
    }

    private static func makePaths(from baseURL: URL) -> Paths {
        let hfHomeURL = baseURL.appendingPathComponent("models", isDirectory: true)
        let hfHubCacheURL = hfHomeURL.appendingPathComponent("hub", isDirectory: true)
        let temporaryURL = baseURL.appendingPathComponent("tmp", isDirectory: true)

        return Paths(
            baseURL: baseURL,
            hfHomeURL: hfHomeURL,
            hfHubCacheURL: hfHubCacheURL,
            temporaryURL: temporaryURL
        )
    }

    /// Try to create the actual directory tree we need.
    /// Returns true if all directories were created (or already exist).
    private static func tryCreateDirectories(_ paths: Paths, label: String) -> Bool {
        let fileManager = FileManager.default
        let dirs = [paths.hfHubCacheURL, paths.temporaryURL]

        for dir in dirs {
            do {
                try fileManager.createDirectory(
                    at: dir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                NSLog(
                    "[OndeEnvironmentBootstrap] %@ not usable — failed to create %@: %@",
                    label, dir.path, error.localizedDescription
                )
                return false
            }
        }

        // Verify we can actually write a file (not just create dirs)
        let probeFile = paths.temporaryURL.appendingPathComponent("probe")
        do {
            try Data([0x42]).write(to: probeFile)
            try fileManager.removeItem(at: probeFile)
        } catch {
            NSLog(
                "[OndeEnvironmentBootstrap] %@ not usable — write probe failed: %@",
                label, error.localizedDescription
            )
            return false
        }

        NSLog("[OndeEnvironmentBootstrap] %@ is writable: %@", label, paths.baseURL.path)
        return true
    }

    // MARK: - Helpers

    private static func directorySize(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        guard
            let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return 0
        }

        var totalSize: Int64 = 0

        for case let fileURL as URL in enumerator {
            guard
                let resourceValues = try? fileURL.resourceValues(forKeys: [
                    .isRegularFileKey, .fileSizeKey,
                ]),
                resourceValues.isRegularFile == true,
                let fileSize = resourceValues.fileSize
            else {
                continue
            }

            totalSize += Int64(fileSize)
        }

        return totalSize
    }
}
