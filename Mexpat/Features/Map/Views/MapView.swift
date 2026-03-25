import SwiftUI
import MapKit

struct MapView: View {
    @State private var viewModel = MapViewModel()
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
                    ForEach(viewModel.pins) { pin in
                        Annotation(pin.title, coordinate: pin.coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                                .padding(6)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea()

                VStack {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.top, 12)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Map")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadCoworkingPins() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            .task {
                await viewModel.loadCoworkingPins()
                if let first = viewModel.pins.first {
                    position = .region(
                        MKCoordinateRegion(
                            center: first.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
                        )
                    )
                }
            }
        }
    }
}

#Preview {
    MapView()
}
