import Foundation

struct AccountUser: Decodable, Equatable, Hashable, Sendable {
    let id: Int
    let email: String
    let name: String?
    let username: String?
    let createdAt: String
    let updatedAt: String
    let passwordRulesSummary: String?

    var displayName: String {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedName, !trimmedName.isEmpty {
            return trimmedName
        }

        return email
    }

    var preferredTitle: String {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedName, !trimmedName.isEmpty {
            return trimmedName
        }

        if let usernameDisplay {
            return usernameDisplay
        }

        return email
    }

    var usernameDisplay: String? {
        let trimmedUsername = username?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmedUsername, !trimmedUsername.isEmpty else { return nil }
        return "@\(trimmedUsername)"
    }
}

struct AccountSignupResult: Decodable, Equatable, Hashable, Sendable {
    let code: Int?
    let message: String
    let userId: Int?
    let userEmail: String?
    let userCreatedAt: String?
}

private enum AccountLoginStatus: Decodable, Sendable {
    case notFound
    case ready(accessToken: String)
    case incomplete(errorCode: UInt32)

    private enum CodingKeys: String, CodingKey {
        case status
        case accessToken
        case errorCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let status = try container.decode(String.self, forKey: .status)

        switch status {
        case "notFound":
            self = .notFound
        case "ready":
            self = .ready(accessToken: try container.decode(String.self, forKey: .accessToken))
        case "incomplete":
            self = .incomplete(errorCode: try container.decode(UInt32.self, forKey: .errorCode))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .status,
                in: container,
                debugDescription: "Unsupported login status \(status)"
            )
        }
    }
}

private struct AccountProxyError: Decodable {
    let errorCode: Int?
    let message: String?
    let error: String?
}

private struct AccountActionMessage: Decodable {
    let message: String
}

enum AccountProxyEnvironment: String, CaseIterable, Identifiable {
    case development
    case production

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .development: return "Development"
        case .production: return "Production"
        }
    }

    var baseURL: URL {
        switch self {
        case .development:
            let host = Bundle.main.object(forInfoDictionaryKey: "OndeWebDevHost") as? String
            let port = Bundle.main.object(forInfoDictionaryKey: "OndeWebDevPort") as? String
            let resolvedHost = (host?.isEmpty == false) ? host! : "localhost"
            let resolvedPort = (port?.isEmpty == false) ? port! : "3000"
            return URL(string: "http://\(resolvedHost):\(resolvedPort)")!
        case .production:
            return URL(string: "https://ondeinference.com")!
        }
    }

    var badgeColor: String {
        switch self {
        case .development: return "orange"
        case .production: return "green"
        }
    }
}

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var currentUser: AccountUser?
    @Published private(set) var accessToken: String?
    @Published private(set) var isBusy = false
    @Published var notice: String?
    @Published var errorMessage: String?

    @Published private(set) var proxyEnvironment: AccountProxyEnvironment

    private let userDefaults: UserDefaults
    private let session: URLSession
    private let decoder: JSONDecoder
    private var gatewayBaseURL: URL
    private var hasAttemptedRestore = false

    init(
        userDefaults: UserDefaults = .standard,
        session: URLSession = .shared
    ) {
        let savedEnvironmentRaw = userDefaults.string(forKey: Keys.proxyEnvironment)
        let savedEnvironment =
            savedEnvironmentRaw.flatMap(AccountProxyEnvironment.init(rawValue:)) ?? .production

        self.userDefaults = userDefaults
        self.session = session
        self.proxyEnvironment = savedEnvironment
        self.gatewayBaseURL = savedEnvironment.baseURL
        self.accessToken = userDefaults.string(forKey: Keys.accessToken)
        self.currentUser = nil

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    /// Switches the active proxy environment, signs out, and persists the choice.
    func switchEnvironment(_ environment: AccountProxyEnvironment) {
        guard environment != proxyEnvironment else { return }
        proxyEnvironment = environment
        gatewayBaseURL = environment.baseURL
        userDefaults.set(environment.rawValue, forKey: Keys.proxyEnvironment)
        hasAttemptedRestore = false
        signOutLocally()
        notice = "Switched to \(environment.displayName). Sign in again."
    }

    var isSignedIn: Bool {
        currentUser != nil && accessToken != nil
    }

    var statusTitle: String {
        if let currentUser {
            return currentUser.preferredTitle
        }

        return "Signed out"
    }

    var statusDetail: String {
        if currentUser != nil {
            return "Your account is ready on this device."
        }

        return "Sign in or create an account to keep your profile ready in Klepon."
    }

    func restoreSessionIfNeeded() async {
        guard !hasAttemptedRestore else { return }
        hasAttemptedRestore = true

        guard accessToken != nil else { return }

        await refreshProfile(showNoticeOnSuccess: false)
    }

    @discardableResult
    func login(email: String, password: String) async -> Bool {
        isBusy = true
        clearTransientMessages()
        defer { isBusy = false }

        do {
            let status: AccountLoginStatus = try await requestJSON(
                path: "api/auth/sign-in",
                method: "POST",
                payload: [
                    "email": normalized(email),
                    "password": password,
                ]
            )

            switch status {
            case .ready(let accessToken):
                self.accessToken = accessToken
                userDefaults.set(accessToken, forKey: Keys.accessToken)
                return await refreshProfile(showNoticeOnSuccess: true)

            case .notFound:
                errorMessage = "We could not find an account for that email address."
                return false

            case .incomplete:
                errorMessage =
                    "Your account isn’t ready yet. Confirm your email first, or resend the confirmation email below."
                return false
            }
        } catch {
            errorMessage = describe(error)
            return false
        }
    }

    @discardableResult
    func signUp(email: String, password: String) async -> AccountSignupResult? {
        isBusy = true
        clearTransientMessages()
        defer { isBusy = false }

        do {
            let result: AccountSignupResult = try await requestJSON(
                path: "api/auth/sign-up",
                method: "POST",
                payload: [
                    "email": normalized(email),
                    "password": password,
                ]
            )
            notice = result.message
            return result
        } catch {
            errorMessage = describe(error)
            return nil
        }
    }

    @discardableResult
    func resendConfirmation(email: String) async -> Bool {
        let normalizedEmail = normalized(email)
        guard !normalizedEmail.isEmpty else {
            errorMessage = "Enter your email first."
            return false
        }

        isBusy = true
        clearTransientMessages()
        defer { isBusy = false }

        do {
            let response: AccountActionMessage = try await requestJSON(
                path: "api/auth/resend-confirmation",
                method: "POST",
                payload: [
                    "email": normalizedEmail
                ]
            )
            notice = response.message
            return true
        } catch {
            errorMessage = describe(error)
            return false
        }
    }

    @discardableResult
    func requestPasswordReset(email: String) async -> Bool {
        let normalizedEmail = normalized(email)
        guard !normalizedEmail.isEmpty else {
            errorMessage = "Enter your email first."
            return false
        }

        isBusy = true
        clearTransientMessages()
        defer { isBusy = false }

        do {
            let response: AccountActionMessage = try await requestJSON(
                path: "api/auth/reset-password",
                method: "POST",
                payload: [
                    "email": normalizedEmail
                ]
            )
            notice = response.message
            return true
        } catch {
            errorMessage = describe(error)
            return false
        }
    }

    @discardableResult
    func updateProfile(name: String, username: String) async -> Bool {
        guard let accessToken else {
            errorMessage = "Sign in before updating your profile."
            return false
        }

        isBusy = true
        clearTransientMessages()
        defer { isBusy = false }

        do {
            currentUser = try await requestJSON(
                path: "api/auth/me",
                method: "PATCH",
                accessToken: accessToken,
                payload: [
                    "name": normalizedProfileField(name),
                    "username": normalizedUsername(username),
                ]
            )
            notice = "Profile updated."
            return true
        } catch {
            errorMessage = describe(error)
            return false
        }
    }

    @discardableResult
    func updatePassword(
        currentPassword: String,
        newPassword: String,
        passwordConfirmation: String
    ) async -> Bool {
        guard let accessToken else {
            errorMessage = "Sign in before updating your password."
            return false
        }

        isBusy = true
        clearTransientMessages()
        defer { isBusy = false }

        do {
            let response: AccountActionMessage = try await requestJSON(
                path: "api/auth/password",
                method: "PATCH",
                accessToken: accessToken,
                payload: [
                    "currentPassword": currentPassword,
                    "password": newPassword,
                    "passwordConfirmation": passwordConfirmation,
                ]
            )
            notice = response.message
            return true
        } catch {
            errorMessage = describe(error)
            return false
        }
    }

    @discardableResult
    func refreshProfile(showNoticeOnSuccess: Bool = true) async -> Bool {
        guard let accessToken else { return false }

        isBusy = true
        if !showNoticeOnSuccess {
            errorMessage = nil
        } else {
            clearTransientMessages()
        }
        defer { isBusy = false }

        do {
            currentUser = try await requestJSON(
                path: "api/auth/me",
                method: "GET",
                accessToken: accessToken
            )
            if showNoticeOnSuccess, let currentUser {
                notice = "Signed in as \(currentUser.email)."
            }
            return true
        } catch {
            signOutLocally()
            errorMessage = describe(error)
            return false
        }
    }

    func logout() async {
        guard let accessToken else {
            signOutLocally()
            return
        }

        isBusy = true
        clearTransientMessages()
        defer { isBusy = false }

        do {
            try await requestVoid(
                path: "api/auth/sign-out",
                method: "POST",
                accessToken: accessToken
            )
            signOutLocally()
            notice = "Signed out."
        } catch {
            signOutLocally()
            errorMessage = describe(error)
        }
    }

    func removeAccount() async {
        guard let accessToken else {
            errorMessage = "Sign in before removing the account."
            return
        }

        isBusy = true
        clearTransientMessages()
        defer { isBusy = false }

        do {
            try await requestVoid(
                path: "api/auth/account",
                method: "DELETE",
                accessToken: accessToken
            )
            signOutLocally()
            notice = "Account removed."
        } catch {
            errorMessage = describe(error)
        }
    }

    private func requestVoid(
        path: String,
        method: String,
        accessToken: String? = nil,
        payload: [String: Any]? = nil
    ) async throws {
        let request = try makeRequest(
            path: path,
            method: method,
            accessToken: accessToken,
            payload: payload
        )
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    private func requestJSON<Response: Decodable>(
        path: String,
        method: String,
        accessToken: String? = nil,
        payload: [String: Any]? = nil
    ) async throws -> Response {
        let request = try makeRequest(
            path: path,
            method: method,
            accessToken: accessToken,
            payload: payload
        )
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(Response.self, from: data)
    }

    private func makeRequest(
        path: String,
        method: String,
        accessToken: String?,
        payload: [String: Any]?
    ) throws -> URLRequest {
        var components = URLComponents(
            url: gatewayBaseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "env", value: proxyEnvironment.rawValue)
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accessToken {
            request.setValue(
                "Bearer \(normalizedToken(accessToken))",
                forHTTPHeaderField: "Authorization"
            )
        }

        if let payload {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        }

        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(response.statusCode) else {
            throw proxyError(from: data, statusCode: response.statusCode)
        }
    }

    private func proxyError(from data: Data, statusCode: Int) -> NSError {
        let proxyError = try? decoder.decode(AccountProxyError.self, from: data)
        let message = proxyError?.message ?? proxyError?.error ?? "Request failed (\(statusCode))."

        return NSError(
            domain: "KleponAccountProxy",
            code: proxyError?.errorCode ?? statusCode,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    private func signOutLocally() {
        currentUser = nil
        accessToken = nil
        userDefaults.removeObject(forKey: Keys.accessToken)
    }

    private func clearTransientMessages() {
        notice = nil
        errorMessage = nil
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedProfileField(_ value: String) -> String {
        normalized(value)
    }

    private func normalizedUsername(_ value: String) -> String {
        normalized(value).lowercased()
    }

    private func normalizedToken(_ token: String) -> String {
        var normalized = token.trimmingCharacters(in: .whitespacesAndNewlines)

        while normalized.lowercased().hasPrefix("bearer ") {
            normalized = String(normalized.dropFirst(7)).trimmingCharacters(
                in: .whitespacesAndNewlines)
        }

        return normalized
    }

    private func describe(_ error: Error) -> String {
        error.localizedDescription
    }
}

private enum Keys {
    static let accessToken = "klepon.account.accessToken"
    static let proxyEnvironment = "klepon.account.proxyEnvironment"
}
