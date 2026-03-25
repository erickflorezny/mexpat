import Foundation

@MainActor
final class AppContainer {
    let supabaseService: SupabaseServicing

    init(supabaseService: SupabaseServicing = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
}
