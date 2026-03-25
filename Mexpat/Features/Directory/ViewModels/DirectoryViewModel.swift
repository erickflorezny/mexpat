import Foundation
import Observation

@MainActor
@Observable
final class DirectoryViewModel {
    private let service: SupabaseServicing

    var listings: [DirectoryListing] = []
    var selectedTag: String = "#Coworking"
    var isLoading: Bool = false
    var errorMessage: String?

    init(service: SupabaseServicing = SupabaseService.shared) {
        self.service = service
    }

    func loadSelectedTag() async {
        await load(tag: selectedTag)
    }

    func load(tag: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            listings = try await service.fetchListings(tag: tag, limit: 50, offset: 0)
        } catch {
            errorMessage = "Could not load listings. Please try again."
        }
    }

    func refresh() async {
        await load(tag: selectedTag)
    }
}
