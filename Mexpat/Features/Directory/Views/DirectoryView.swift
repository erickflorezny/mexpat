import SwiftUI

struct DirectoryView: View {
    @State private var viewModel = DirectoryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.10),
                        Color.cyan.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.listings.isEmpty {
                        ProgressView("Loading")
                    } else if let errorMessage = viewModel.errorMessage {
                        ContentUnavailableView(
                            "Couldn’t load directory",
                            systemImage: "wifi.exclamationmark",
                            description: Text(errorMessage)
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.listings) { listing in
                                    GlassListingCard(listing: listing)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                        .refreshable {
                            await viewModel.refresh()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
            .navigationTitle("Directory")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("#Coworking") { Task { await viewModel.load(tag: "#Coworking") } }
                        Button("#Business") { Task { await viewModel.load(tag: "#Business") } }
                        Button("#Class") { Task { await viewModel.load(tag: "#Class") } }
                    } label: {
                        Label("Tags", systemImage: "tag")
                    }
                }
            }
            .task {
                if viewModel.listings.isEmpty {
                    await viewModel.loadSelectedTag()
                }
            }
        }
    }
}

private struct GlassListingCard: View {
    let listing: DirectoryListing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(listing.title)
                    .font(.headline)
                Spacer()
                Text(listing.kind)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if let description = listing.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if let address = listing.address {
                Label(address, systemImage: "mappin.and.ellipse")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !listing.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(listing.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
        )
    }
}

#Preview {
    DirectoryView()
}
