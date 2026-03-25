import Foundation
import Observation

@MainActor
@Observable
final class AdminLegalViewModel {
    private let service: SupabaseServicing

    var milestones: [AdminLegalMilestone] = []
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    init(service: SupabaseServicing = SupabaseService.shared) {
        self.service = service
    }

    func loadMilestones() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            milestones = try await service.fetchAdminLegalMilestones(limit: 200, offset: 0)
        } catch {
            errorMessage = "Admin data unavailable. Confirm admin role claim in app_metadata."
            milestones = []
        }
    }

    func revert(_ milestone: AdminLegalMilestone) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let reverted = try await service.revertLegalMilestoneAdmin(id: milestone.id)
            if let idx = milestones.firstIndex(where: { $0.id == reverted.id }) {
                milestones[idx] = AdminLegalMilestone(
                    id: reverted.id,
                    userID: milestone.userID,
                    code: reverted.code,
                    title: reverted.title,
                    description: reverted.description,
                    state: reverted.state,
                    progressPercent: reverted.progressPercent,
                    xpReward: reverted.xpReward
                )
            }
            successMessage = "Milestone reverted and XP rollback applied."
        } catch {
            errorMessage = "Could not revert milestone."
        }
    }
}
