import SwiftUI

struct LegalView: View {
    @State private var viewModel = LegalViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.mint.opacity(0.10),
                        Color.blue.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        questHeader
                        accountCard
                        milestonesCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Residency Quest")
            .task {
                await viewModel.loadMilestones()
            }
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

    private var questHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: max(0.01, viewModel.progressFraction))
                    .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("XP")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.totalXP)")
                        .font(.headline)
                }
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text("Your Legal Journey")
                    .font(.headline)
                Text("Track milestones, earn XP, complete residency faster.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(glassBackground)
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Account")
                .font(.subheadline.weight(.semibold))

            if let uid = viewModel.currentUserId {
                Text(uid.uuidString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Text("Sign in from the Auth tab to load your legal milestones.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await viewModel.loadMilestones() }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                } else {
                    Text("Refresh Progress")
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
                Text("Milestones")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.milestones.filter { $0.state == \"completed\" }.count)/\(viewModel.milestones.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.milestones.isEmpty {
                ContentUnavailableView(
                    "No milestones loaded",
                    systemImage: "checklist",
                    description: Text("Sign in and refresh to view Residency Quest progress.")
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.milestones) { milestone in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: milestone.state == "completed" ? "checkmark.seal.fill" : "seal")
                                .foregroundStyle(milestone.state == "completed" ? .green : .secondary)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(milestone.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(milestone.code)
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

                                if milestone.state != "completed" {
                                    Button("Complete") {
                                        HapticFeedback.lightImpact()
                                        Task { await viewModel.complete(milestone) }
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
    LegalView()
}
