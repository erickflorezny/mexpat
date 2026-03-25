import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    private let service: SupabaseServicing

    var email: String = ""
    var password: String = ""
    var isLoading = false
    var isAuthenticated = false
    var errorMessage: String?

    init(service: SupabaseServicing = SupabaseService.shared) {
        self.service = service
    }

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await service.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = "Could not sign in. Check credentials and try again."
        }
    }

    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await service.signUp(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = "Could not create account. Try another email."
        }
    }

    func signOut() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await service.signOut()
            isAuthenticated = false
            password = ""
        } catch {
            errorMessage = "Could not sign out."
        }
    }
}
