import SwiftUI

private enum AccountTextContentType {
    case username
    case password
    case newPassword
}

#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
    typealias AccountKeyboardType = UIKeyboardType
#else
    enum AccountKeyboardType {
        case emailAddress
    }
#endif

private enum AccountFormMode: String, CaseIterable, Identifiable {
    case login = "Log in"
    case signup = "Sign up"

    var id: String { rawValue }
}

struct AccountView: View {
    @EnvironmentObject private var accountStore: AccountStore

    @State private var formMode: AccountFormMode = .login
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    @State private var signupEmail = ""
    @State private var signupPassword = ""
    @State private var signupPasswordConfirmation = ""
    @State private var showingRemoveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                #if os(tvOS)
                    TVPageHeader("Account")
                #endif

                SectionHeader(
                    "Account",
                    subtitle:
                        "Create an account, sign in, and keep your profile ready in Klepon."
                )

                AccountStatusBanner(
                    notice: accountStore.notice,
                    errorMessage: accountStore.errorMessage
                )

                AccountProxyInfoCard()

                if accountStore.isSignedIn {
                    AccountProfileCard(
                        user: accountStore.currentUser,
                        isBusy: accountStore.isBusy,
                        onRefresh: {
                            Task {
                                await accountStore.refreshProfile()
                            }
                        },
                        onSaveProfile: { name, username in
                            await accountStore.updateProfile(name: name, username: username)
                        },
                        onUpdatePassword: { currentPassword, newPassword, passwordConfirmation in
                            await accountStore.updatePassword(
                                currentPassword: currentPassword,
                                newPassword: newPassword,
                                passwordConfirmation: passwordConfirmation
                            )
                        },
                        onLogout: {
                            Task {
                                await accountStore.logout()
                            }
                        },
                        onRemoveAccount: {
                            showingRemoveConfirmation = true
                        }
                    )
                } else {
                    AccountModePicker(formMode: $formMode)

                    if formMode == .login {
                        AccountLoginCard(
                            email: $loginEmail,
                            password: $loginPassword,
                            isBusy: accountStore.isBusy,
                            canSubmit: !loginEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty && !loginPassword.isEmpty,
                            onSubmit: {
                                Task {
                                    let didLogin = await accountStore.login(
                                        email: loginEmail,
                                        password: loginPassword
                                    )
                                    if didLogin {
                                        loginPassword = ""
                                    }
                                }
                            },
                            onResendConfirmation: {
                                Task {
                                    await accountStore.resendConfirmation(email: loginEmail)
                                }
                            },
                            onForgotPassword: {
                                Task {
                                    await accountStore.requestPasswordReset(email: loginEmail)
                                }
                            }
                        )
                    } else {
                        AccountSignupCard(
                            email: $signupEmail,
                            password: $signupPassword,
                            passwordConfirmation: $signupPasswordConfirmation,
                            isBusy: accountStore.isBusy,
                            canSubmit: canSubmitSignup,
                            onSubmit: {
                                Task {
                                    let result = await accountStore.signUp(
                                        email: signupEmail,
                                        password: signupPassword
                                    )

                                    guard result != nil else { return }

                                    loginEmail = signupEmail
                                    loginPassword = signupPassword
                                    signupPassword = ""
                                    signupPasswordConfirmation = ""
                                    formMode = .login
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .kleponReadableContentWidth()
        }
        .background(KleponColor.background.ignoresSafeArea())
        .navigationTitle("Account")
        #if os(tvOS)
            .toolbar(.hidden, for: .navigationBar)
        #else
            .kleponInlineNavigationTitle()
        #endif
        .task {
            await accountStore.restoreSessionIfNeeded()
        }
        .confirmationDialog(
            "Delete this account?",
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove account", role: .destructive) {
                Task {
                    await accountStore.removeAccount()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This permanently removes the account tied to your current session."
            )
        }
    }

    private var canSubmitSignup: Bool {
        !signupEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !signupPassword.isEmpty
            && signupPassword == signupPasswordConfirmation
    }
}

struct AccountSettingsCard: View {
    @EnvironmentObject private var accountStore: AccountStore

    var body: some View {
        NavigationLink {
            AccountView()
        } label: {
            KleponCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(
                            systemName: accountStore.isSignedIn
                                ? "person.crop.circle.badge.checkmark" : "person.crop.circle"
                        )
                        .font(.system(size: 24))
                        .foregroundStyle(KleponColor.accent)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Account")
                                .font(KleponTypography.cardTitle)
                                .foregroundStyle(KleponColor.textPrimary)

                            Text(accountStore.statusTitle)
                                .font(KleponTypography.bodySecondary.weight(.semibold))
                                .foregroundStyle(KleponColor.textPrimary)

                            Text(accountStore.statusDetail)
                                .font(KleponTypography.caption)
                                .foregroundStyle(KleponColor.textSecondary)
                        }

                        Spacer(minLength: 12)

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(KleponColor.textSecondary)
                    }

                    HStack(spacing: 10) {
                        KleponChip(
                            title: "Email account",
                            icon: "person.crop.circle"
                        )

                        KleponChip(
                            title: accountStore.isSignedIn ? "Profile ready" : "Signed out",
                            icon: accountStore.isSignedIn
                                ? "checkmark.circle" : "rectangle.portrait.and.arrow.right"
                        )
                    }
                }
            }
        }
        .kleponInteractiveButtonStyle()
    }
}

private struct AccountStatusBanner: View {
    let notice: String?
    let errorMessage: String?

    var body: some View {
        if let errorMessage {
            KleponCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Something needs attention", systemImage: "exclamationmark.triangle.fill")
                        .font(KleponTypography.bodySecondary.weight(.semibold))
                        .foregroundStyle(KleponColor.highlight)

                    Text(errorMessage)
                        .font(KleponTypography.bodySecondary)
                        .foregroundStyle(KleponColor.textSecondary)
                }
            }
        } else if let notice {
            KleponCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Status", systemImage: "checkmark.circle.fill")
                        .font(KleponTypography.bodySecondary.weight(.semibold))
                        .foregroundStyle(KleponColor.accent)

                    Text(notice)
                        .font(KleponTypography.bodySecondary)
                        .foregroundStyle(KleponColor.textSecondary)
                }
            }
        }
    }
}

private struct AccountProxyInfoCard: View {
    var body: some View {
        KleponCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Private sign in")
                    .font(KleponTypography.cardTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text(
                    "Create your account, confirm your email, and reset your password right from Klepon."
                )
                .font(KleponTypography.bodySecondary)
                .foregroundStyle(KleponColor.textSecondary)

                HStack(spacing: 10) {
                    KleponChip(title: "Email sign in", icon: "envelope")
                    KleponChip(title: "Password reset", icon: "key")
                }
            }
        }
    }
}

private struct AccountModePicker: View {
    @Binding var formMode: AccountFormMode

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AccountFormMode.allCases) { mode in
                Button {
                    formMode = mode
                } label: {
                    Text(mode.rawValue)
                        .font(KleponTypography.bodySecondary.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    formMode == mode
                                        ? KleponColor.accent : KleponColor.surfaceSecondary)
                        )
                        .foregroundStyle(formMode == mode ? Color.white : KleponColor.textPrimary)
                }
                .kleponInteractiveButtonStyle()
            }
        }
    }
}

private struct AccountLoginCard: View {
    @Binding var email: String
    @Binding var password: String

    let isBusy: Bool
    let canSubmit: Bool
    let onSubmit: () -> Void
    let onResendConfirmation: () -> Void
    let onForgotPassword: () -> Void

    private var canRequestEmailAction: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        KleponCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Log in")
                    .font(KleponTypography.cardTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text(
                    "Use your email and password to sign in, resend your confirmation email, or reset your password."
                )
                .font(KleponTypography.bodySecondary)
                .foregroundStyle(KleponColor.textSecondary)

                AccountInputField(
                    title: "Email",
                    placeholder: "you@example.com",
                    text: $email,
                    textContentType: .username,
                    keyboard: .emailAddress
                )

                AccountInputField(
                    title: "Password",
                    placeholder: "Enter your password",
                    text: $password,
                    isSecure: true,
                    textContentType: .password
                )

                KleponActionButton(
                    title: "Log in",
                    systemImage: "arrow.right.circle.fill",
                    isLoading: isBusy,
                    isDisabled: !canSubmit,
                    action: onSubmit
                )

                VStack(spacing: 10) {
                    KleponActionButton(
                        title: "Resend confirmation email",
                        systemImage: "envelope.badge",
                        tone: .secondary,
                        isDisabled: isBusy || !canRequestEmailAction,
                        action: onResendConfirmation
                    )

                    KleponActionButton(
                        title: "Forgot password",
                        systemImage: "key",
                        tone: .secondary,
                        isDisabled: isBusy || !canRequestEmailAction,
                        action: onForgotPassword
                    )
                }
            }
        }
    }
}

private struct AccountSignupCard: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var passwordConfirmation: String

    let isBusy: Bool
    let canSubmit: Bool
    let onSubmit: () -> Void

    private var passwordsMatch: Bool {
        !password.isEmpty && password == passwordConfirmation
    }

    var body: some View {
        KleponCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sign up")
                    .font(KleponTypography.cardTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text(
                    "Create your account, then confirm your email before your first sign in."
                )
                .font(KleponTypography.bodySecondary)
                .foregroundStyle(KleponColor.textSecondary)

                AccountInputField(
                    title: "Email",
                    placeholder: "new-user@example.com",
                    text: $email,
                    textContentType: .username,
                    keyboard: .emailAddress
                )

                AccountInputField(
                    title: "Password",
                    placeholder: "Choose a password",
                    text: $password,
                    isSecure: true,
                    textContentType: .newPassword
                )

                AccountInputField(
                    title: "Confirm password",
                    placeholder: "Type it again",
                    text: $passwordConfirmation,
                    isSecure: true,
                    textContentType: .newPassword
                )

                if !passwordConfirmation.isEmpty {
                    Label(
                        passwordsMatch ? "Passwords match" : "Passwords must match",
                        systemImage: passwordsMatch
                            ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .font(KleponTypography.caption)
                    .foregroundStyle(passwordsMatch ? KleponColor.accent : KleponColor.highlight)
                }

                KleponActionButton(
                    title: "Create account",
                    systemImage: "person.badge.plus",
                    isLoading: isBusy,
                    isDisabled: !canSubmit,
                    action: onSubmit
                )
            }
        }
    }
}

private struct AccountProfileCard: View {
    let user: AccountUser?
    let isBusy: Bool
    let onRefresh: () -> Void
    let onSaveProfile: (String, String) async -> Bool
    let onUpdatePassword: (String, String, String) async -> Bool
    let onLogout: () -> Void
    let onRemoveAccount: () -> Void

    @State private var isEditingProfile = false
    @State private var name = ""
    @State private var username = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var newPasswordConfirmation = ""

    var body: some View {
        KleponCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Text("Profile")
                        .font(KleponTypography.cardTitle)
                        .foregroundStyle(KleponColor.textPrimary)

                    Spacer()

                    if user != nil && !isEditingProfile {
                        Button("Edit") {
                            resetDraftValues()
                            isEditingProfile = true
                        }
                        .font(KleponTypography.caption.weight(.semibold))
                        .foregroundStyle(KleponColor.accent)
                        .disabled(isBusy)
                    }
                }

                if let user {
                    KleponMetadataRow(
                        title: "Name",
                        value: user.name?.isEmpty == false ? (user.name ?? "Not set") : "Not set"
                    )
                    KleponMetadataRow(
                        title: "Username",
                        value: user.usernameDisplay ?? "Not set"
                    )
                    KleponMetadataRow(title: "Email", value: user.email)
                    KleponMetadataRow(title: "User ID", value: "\(user.id)")
                    KleponMetadataRow(title: "Created", value: user.createdAt)
                    KleponMetadataRow(title: "Updated", value: user.updatedAt)
                } else {
                    Text("Klepon is still loading the profile details for this session.")
                        .font(KleponTypography.bodySecondary)
                        .foregroundStyle(KleponColor.textSecondary)
                }

                if isEditingProfile {
                    AccountInputField(
                        title: "Name",
                        placeholder: "Your name",
                        text: $name
                    )

                    AccountInputField(
                        title: "Username",
                        placeholder: "yourname",
                        text: $username
                    )

                    Text(
                        "Use lowercase letters, numbers, dots, dashes, and underscores for your username."
                    )
                    .font(KleponTypography.caption)
                    .foregroundStyle(KleponColor.textSecondary)

                    HStack(spacing: 10) {
                        KleponActionButton(
                            title: "Save profile",
                            systemImage: "checkmark.circle.fill",
                            isLoading: isBusy,
                            action: {
                                Task {
                                    let didSave = await onSaveProfile(name, username)
                                    if didSave {
                                        isEditingProfile = false
                                    }
                                }
                            }
                        )

                        KleponActionButton(
                            title: "Cancel",
                            systemImage: "xmark.circle",
                            tone: .secondary,
                            isDisabled: isBusy,
                            action: {
                                resetDraftValues()
                                isEditingProfile = false
                            }
                        )
                    }
                }

                if user != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Password")
                            .font(KleponTypography.bodySecondary.weight(.semibold))
                            .foregroundStyle(KleponColor.textPrimary)

                        if let passwordRulesSummary = user?.passwordRulesSummary,
                            !passwordRulesSummary.isEmpty
                        {
                            Text("Use \(passwordRulesSummary).")
                                .font(KleponTypography.caption)
                                .foregroundStyle(KleponColor.textSecondary)
                        }

                        AccountInputField(
                            title: "Current password",
                            placeholder: "Your current password",
                            text: $currentPassword,
                            isSecure: true,
                            textContentType: .password
                        )

                        AccountInputField(
                            title: "New password",
                            placeholder: "Choose a new password",
                            text: $newPassword,
                            isSecure: true,
                            textContentType: .newPassword
                        )

                        AccountInputField(
                            title: "Confirm new password",
                            placeholder: "Type it again",
                            text: $newPasswordConfirmation,
                            isSecure: true,
                            textContentType: .newPassword
                        )

                        if !newPasswordConfirmation.isEmpty
                            && newPassword != newPasswordConfirmation
                        {
                            Label(
                                "New password and confirmation must match",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .font(KleponTypography.caption)
                            .foregroundStyle(KleponColor.highlight)
                        }

                        KleponActionButton(
                            title: "Update password",
                            systemImage: "key.fill",
                            tone: .secondary,
                            isLoading: isBusy,
                            isDisabled: currentPassword.isEmpty || newPassword.isEmpty
                                || newPasswordConfirmation.isEmpty
                                || newPassword != newPasswordConfirmation,
                            action: {
                                Task {
                                    let didUpdate = await onUpdatePassword(
                                        currentPassword,
                                        newPassword,
                                        newPasswordConfirmation
                                    )
                                    if didUpdate {
                                        currentPassword = ""
                                        newPassword = ""
                                        newPasswordConfirmation = ""
                                    }
                                }
                            }
                        )
                    }
                }

                HStack(spacing: 10) {
                    KleponActionButton(
                        title: "Refresh profile",
                        systemImage: "arrow.clockwise",
                        tone: .secondary,
                        isLoading: isBusy,
                        isDisabled: user == nil,
                        action: onRefresh
                    )

                    KleponActionButton(
                        title: "Log out",
                        systemImage: "rectangle.portrait.and.arrow.right",
                        tone: .secondary,
                        isDisabled: isBusy,
                        action: onLogout
                    )
                }

                KleponActionButton(
                    title: "Delete account",
                    systemImage: "trash",
                    tone: .secondary,
                    isDisabled: isBusy,
                    action: onRemoveAccount
                )
            }
            .onAppear {
                resetDraftValues()
            }
            .onChange(of: user?.updatedAt ?? "") { _, _ in
                resetDraftValues()
            }
        }
    }

    private func resetDraftValues() {
        name = user?.name ?? ""
        username = user?.username ?? ""
    }
}

private struct AccountInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var textContentType: AccountTextContentType? = nil
    var keyboard: AccountKeyboardType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(KleponTypography.caption)
                .foregroundStyle(KleponColor.accentWarm)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(KleponTypography.body)
            .foregroundColor(KleponColor.textPrimary)
            .applyPlainTextFieldStyleForPlatform()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(KleponColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(KleponColor.divider, lineWidth: 1)
            )
            .applyAccountInputTraits(textContentType: textContentType, keyboard: keyboard)
            .disableAutocorrectionForPlatform()
            .disableAutocapitalizationForPlatform()
        }
    }
}

extension View {
    @ViewBuilder
    fileprivate func modifyIfLet<Value, Modified: View>(
        _ value: Value?,
        @ViewBuilder transform: (Self, Value) -> Modified
    ) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }

    @ViewBuilder
    fileprivate func applyAccountInputTraits(
        textContentType: AccountTextContentType?,
        keyboard: AccountKeyboardType?
    ) -> some View {
        #if os(iOS) || os(tvOS) || os(visionOS)
            self
                .modifyIfLet(textContentType) { view, textContentType in
                    switch textContentType {
                    case .username:
                        view.textContentType(.username)
                    case .password:
                        view.textContentType(.password)
                    case .newPassword:
                        view.textContentType(.newPassword)
                    }
                }
                .modifyIfLet(keyboard) { view, keyboard in
                    view.keyboardType(keyboard)
                }
        #else
            self
        #endif
    }

    @ViewBuilder
    fileprivate func disableAutocorrectionForPlatform() -> some View {
        #if os(iOS) || os(tvOS) || os(visionOS)
            self.autocorrectionDisabled()
        #else
            self
        #endif
    }

    @ViewBuilder
    fileprivate func disableAutocapitalizationForPlatform() -> some View {
        #if os(iOS) || os(tvOS) || os(visionOS)
            self.textInputAutocapitalization(.never)
        #else
            self
        #endif
    }

    @ViewBuilder
    fileprivate func applyPlainTextFieldStyleForPlatform() -> some View {
        #if os(macOS)
            self.textFieldStyle(.plain)
        #else
            self
        #endif
    }
}
