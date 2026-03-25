import Foundation
import Observation

@MainActor
@Observable
final class LegalViewModel {
    private let service: SupabaseServicing

    var milestones: [LegalMilestone] = []
    var currentUserId: UUID?
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    var totalXP: Int {
        milestones
            .filter { $0.state == "completed" }
            .reduce(0) { $0 + $1.xpReward }
    }

    var progressFraction: Double {
        guard !milestones.isEmpty else { return 0 }
        let completed = milestones.filter { $0.state == "completed" }.count
        return Double(completed) / Double(milestones.count)
    }

    init(service: SupabaseServicing = SupabaseService.shared) {
        self.service = service
    }

    func loadMilestones() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            currentUserId = try await service.currentUserID()
            milestones = try await service.fetchLegalMilestones()
        } catch {
            errorMessage = "Could not load Residency Quest milestones. Please sign in first."
            milestones = []
        }
    }

    func complete(_ milestone: LegalMilestone) async {
        guard let index = milestones.firstIndex(where: { $0.id == milestone.id }) else {
            return
        }

        let original = milestones[index]
        milestones[index] = LegalMilestone(
            id: original.id,
            code: original.code,
            title: original.title,
            description: original.description,
            state: "completed",
            progressPercent: 100,
            xpReward: original.xpReward,
            dueDate: original.dueDate,
            completedAt: original.completedAt
        )

        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let updated = try await service.completeLegalMilestone(id: milestone.id)
            milestones[index] = updated
            successMessage = "Milestone completed. XP awarded."
        } catch {
            milestones[index] = original
            errorMessage = "Could not complete milestone right now."
        }
    }
}
