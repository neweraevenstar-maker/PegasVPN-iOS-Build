import SwiftUI
import AuthenticationServices

struct VPNAccountView: View {
    @ObservedObject var vpnManager: VPNManager
    @AppStorage("PegasVPN.accountMethod") private var accountMethod = "guest"

    @State private var email = ""
    @State private var code = ""
    @State private var codeSent = false
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var nonce = ""
    @State private var confirmDeletion = false
    @State private var deleted = false

    var body: some View {
        Form {
            Section("Account") {
                Label(
                    accountMethod == "guest" ? "Guest access" :
                    accountMethod == "apple" ? "Signed in with Apple" :
                    "Signed in with email",
                    systemImage: "person.crop.circle"
                )
                if accountMethod == "guest" {
                    Text("Sign in to keep your account across sessions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if accountMethod == "guest" {
                Section("Sign in with Apple") {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            nonce = VPNAccountAPI.makeNonce()
                            request.nonce = VPNAccountAPI.hashedNonce(nonce)
                            request.requestedScopes = [.email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                guard let credential =
                                    authorization.credential
                                        as? ASAuthorizationAppleIDCredential,
                                      let token = credential.identityToken
                                else {
                                    errorMessage = "Apple identity token missing"
                                    return
                                }
                                let submittedNonce = nonce
                                Task { @MainActor in
                                    await perform {
                                        try await VPNAccountAPI.signInApple(
                                            identityToken: token,
                                            nonce: submittedNonce
                                        )
                                        await completeSignIn()
                                    }
                                }
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 48)
                    .disabled(isBusy)
                }

                Section("Sign in with email") {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if codeSent {
                        TextField("Six-digit code", text: $code)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)

                        Button("Verify and sign in") {
                            Task {
                                await perform {
                                    try await VPNAccountAPI.signInEmail(
                                        email: email, code: code.trimmingCharacters(in: .whitespacesAndNewlines)
                                    )
                                    await completeSignIn()
                                }
                            }
                        }
                        .disabled(isBusy || code.trimmingCharacters(in: .whitespacesAndNewlines).count != 6)
                    }

                    Button(codeSent ? "Resend code" : "Email me a code") {
                        Task {
                            await perform {
                                try await VPNAccountAPI.requestEmailCode(email.trimmingCharacters(in: .whitespacesAndNewlines))
                                codeSent = true
                            }
                        }
                    }
                    .disabled(isBusy || !email.contains("@"))
                }
            }

            Section("Account management") {
                if accountMethod == "guest" {
                    Text(
                        "Have an active Apple subscription? Sign in with Apple "
                        + "or email before deleting your guest account. "
                        + "Guest-only purchases may not be recoverable."
                    )
                    .font(.footnote)
                    .foregroundStyle(.orange)
                }

                Button("Delete account", role: .destructive) {
                    confirmDeletion = true
                }
                .disabled(isBusy || deleted)

                Text(
                    "Deleting your account removes its VPN access. "
                    + "An Apple subscription must be cancelled separately "
                    + "in Settings > Apple Account > Subscriptions."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if isBusy {
                Section {
                    ProgressView("Please wait")
                }
            }
            if let errorMessage {
                Section {
                    PegasStatusNotice(message: errorMessage)
                }
            }
            if deleted {
                Section {
                    Label("Account deleted", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Account")
        .pegasPremiumScreen()
            .scrollContentBackground(.hidden)
        .scrollContentBackground(.hidden)
        .confirmationDialog(
            "Permanently delete your PegasVPN account?",
            isPresented: $confirmDeletion,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) {
                Task {
                    await perform {
                        try await VPNAccountAPI.deleteAccount()
                        await vpnManager.resetAfterAccountDeletion()
                        deleted = true
                    }
                }
            }
        } message: {
            Text(
                "Your VPN access and account will be removed. "
                + "Deleting does not cancel an Apple subscription."
            )
        }
    }

    @MainActor
    private func completeSignIn() async {
        await vpnManager.resetAfterAccountChange()
        // Reconcile StoreKit entitlements silently for the signed-in
        // account; AppStore.sync() is reserved for explicit Restore.
        await VPNSubscriptionStore.shared.refreshStatus()
        await VPNSubscriptionStore.shared.loadAccessStatus()
    }

    @MainActor
    private func perform(
        _ operation: () async throws -> Void
    ) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
