import SwiftUI

@main
struct MexpatApp: App {
    @State private var container = AppContainer()
    @State private var showAdminTab = false

    var body: some Scene {
        WindowGroup {
            TabView {
                AuthView()
                    .tabItem {
                        Label("Auth", systemImage: "person.crop.circle")
                    }

                DirectoryView()
                    .tabItem {
                        Label("Directory", systemImage: "building.2")
                    }

                MapView()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }

                LegalView()
                    .tabItem {
                        Label("Legal", systemImage: "checkmark.seal")
                    }

                if showAdminTab {
                    AdminLegalView()
                        .tabItem {
                            Label("Admin", systemImage: "lock.shield")
                        }
                }
            }
            .environment(container)
            .task {
                showAdminTab = await container.supabaseService.isCurrentUserAdmin()
            }
        }
    }
}
