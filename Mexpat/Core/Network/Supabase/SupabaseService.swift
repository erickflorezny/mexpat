import Foundation
import Supabase

public struct DirectoryListing: Codable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String?
    public let kind: String
    public let address: String?
    public let latitude: Double
    public let longitude: Double
    public let tags: [String]
}

public struct LegalMilestone: Codable, Identifiable, Sendable {
    public let id: UUID
    public let code: String
    public let title: String
    public let description: String?
    public let state: String
    public let progressPercent: Double
    public let xpReward: Int
    public let dueDate: String?
    public let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case title
        case description
        case state
        case progressPercent = "progress_percent"
        case xpReward = "xp_reward"
        case dueDate = "due_date"
        case completedAt = "completed_at"
    }
}

public struct AdminLegalMilestone: Codable, Identifiable, Sendable {
    public let id: UUID
    public let userID: UUID
    public let code: String
    public let title: String
    public let description: String?
    public let state: String
    public let progressPercent: Double
    public let xpReward: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case code
        case title
        case description
        case state
        case progressPercent = "progress_percent"
        case xpReward = "xp_reward"
    }
}

public protocol SupabaseServicing: Sendable {
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func currentUserID() async throws -> UUID
    func isCurrentUserAdmin() async -> Bool
    func fetchListings(tag: String, limit: Int, offset: Int) async throws -> [DirectoryListing]
    func fetchLegalMilestones() async throws -> [LegalMilestone]
    func completeLegalMilestone(id: UUID) async throws -> LegalMilestone
    func fetchAdminLegalMilestones(limit: Int, offset: Int) async throws -> [AdminLegalMilestone]
    func revertLegalMilestoneAdmin(id: UUID) async throws -> LegalMilestone
}

public actor SupabaseService: SupabaseServicing {
    public static let shared = SupabaseService()

    public let client: SupabaseClient

    public init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: urlString),
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        else {
            fatalError("Missing SUPABASE_URL or SUPABASE_ANON_KEY in Info.plist")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }

    public func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(
            email: email,
            password: password
        )
    }

    public func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(
            email: email,
            password: password
        )
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    public func currentUserID() async throws -> UUID {
        let session = try await client.auth.session
        return session.user.id
    }

    public func isCurrentUserAdmin() async -> Bool {
        do {
            _ = try await fetchAdminLegalMilestones(limit: 1, offset: 0)
            return true
        } catch {
            return false
        }
    }

    public func fetchListings(tag: String, limit: Int = 50, offset: Int = 0) async throws -> [DirectoryListing] {
        let normalizedTag = tag
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        return try await client
            .rpc(
                "get_listings_by_tag",
                params: [
                    "p_tag": normalizedTag,
                    "p_limit": limit,
                    "p_offset": offset
                ]
            )
            .execute()
            .value
    }

    public func fetchLegalMilestones() async throws -> [LegalMilestone] {
        let userId = try await currentUserID()

        try await client
            .from("legal_milestones")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    public func completeLegalMilestone(id: UUID) async throws -> LegalMilestone {
        let rows: [LegalMilestone] = try await client
            .rpc(
                "complete_legal_milestone",
                params: [
                    "p_milestone_id": id.uuidString
                ]
            )
            .execute()
            .value

        guard let milestone = rows.first else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No milestone returned from RPC"])
        }

        return milestone
    }

    public func fetchAdminLegalMilestones(limit: Int = 200, offset: Int = 0) async throws -> [AdminLegalMilestone] {
        try await client
            .rpc(
                "admin_list_legal_milestones",
                params: [
                    "p_limit": limit,
                    "p_offset": offset
                ]
            )
            .execute()
            .value
    }

    public func revertLegalMilestoneAdmin(id: UUID) async throws -> LegalMilestone {
        let rows: [LegalMilestone] = try await client
            .rpc(
                "revert_legal_milestone_admin",
                params: [
                    "p_milestone_id": id.uuidString
                ]
            )
            .execute()
            .value

        guard let milestone = rows.first else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No milestone returned from admin revert RPC"])
        }

        return milestone
    }
}
