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
        "About 941 MB"
    }

    static func configureIfNeeded() {
        guard !didConfigure, let paths = paths() else { return }

        [paths.baseURL, paths.hfHomeURL, paths.hfHubCacheURL, paths.temporaryURL].forEach {
            try? FileManager.default.createDirectory(
                at: $0,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        setenv("HF_HOME", paths.hfHomeURL.path, 1)
        setenv("HF_HUB_CACHE", paths.hfHubCacheURL.path, 1)
        setenv("TMPDIR", paths.temporaryURL.path, 1)
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

    static func paths() -> Paths? {
        let fileManager = FileManager.default

        let baseURL: URL
        if let sharedContainer = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.ondeinference.apps"
        ) {
            baseURL = sharedContainer
        } else if let appSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            baseURL = appSupportURL
        } else {
            return nil
        }

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
