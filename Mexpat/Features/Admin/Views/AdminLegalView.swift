import SwiftUI

struct AdminLegalView: View {
    @State private var viewModel = AdminLegalViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.purple.opacity(0.10),
                        Color.blue.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        headerCard
                        milestonesCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Admin Legal")
            .task { await viewModel.loadMilestones() }
            .onChange(of: viewModel.successMessage) { _, newValue in
                guard newValue != nil else { return }
                HapticFeedback.success()
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                guard newValue != nil else { return }
                HapticFeedback.error()
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Moderation")
                .font(.headline)
            Text("Review legal milestones across users and revert incorrect completions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task { await viewModel.loadMilestones() }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                } else {
                    Text("Refresh Admin Data")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
            .buttonStyle(.borderedProminent)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if let success = viewModel.successMessage {
                Text(success)
                    .font(.footnote)
                    .foregroundStyle(.green)
            }
        }
        .padding(16)
        .background(glassBackground)
    }

    private var milestonesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("All Legal Milestones")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.milestones.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.milestones.isEmpty {
                ContentUnavailableView(
                    "No admin records",
                    systemImage: "lock.shield",
                    description: Text("You may not have admin role access.")
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.milestones) { milestone in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: milestone.state == "completed" ? "checkmark.seal.fill" : "seal")
                                .foregroundStyle(milestone.state == "completed" ? .green : .secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(milestone.title)
                                    .font(.subheadline.weight(.semibold))

                                Text("\(milestone.code) · user: \(milestone.userID.uuidString.prefix(8))…")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)

                                if let detail = milestone.description, !detail.isEmpty {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 8) {
                                Text("+\(milestone.xpReward) XP")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.thinMaterial, in: Capsule())

                                if milestone.state == "completed" {
                                    Button("Revert") {
                                        HapticFeedback.lightImpact()
                                        Task { await viewModel.revert(milestone) }
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption2)
                                    .disabled(viewModel.isLoading)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .background(glassBackground)
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    AdminLegalView()
}
