import Foundation
import Observation
import CoreLocation

@MainActor
@Observable
final class MapViewModel {
    struct MapPin: Identifiable {
        let id: UUID
        let title: String
        let subtitle: String
        let coordinate: CLLocationCoordinate2D
    }

    private let service: SupabaseServicing

    var pins: [MapPin] = []
    var isLoading = false
    var errorMessage: String?

    init(service: SupabaseServicing = SupabaseService.shared) {
        self.service = service
    }

    func loadCoworkingPins() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let listings = try await service.fetchListings(tag: "#Coworking", limit: 100, offset: 0)
            pins = listings.map {
                MapPin(
                    id: $0.id,
                    title: $0.title,
                    subtitle: $0.address ?? "Mexico",
                    coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                )
            }
        } catch {
            errorMessage = "Unable to load map pins."
        }
    }
}
