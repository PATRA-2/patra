import SwiftUI

enum MainTab: Hashable {
    case home
    case plantScan
    case radarFeed
    case map
}

typealias HomeTab = MainTab

extension MainTab {
    static let report: MainTab = .plantScan
    static let farms: MainTab = .map
}

struct MainTabView: View {
    let userEmail: String
    let onLogout: () -> Void

    @State private var selectedTab: MainTab = .home
    @State private var isShowingProfileSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
                    .toolbar {
                        if selectedTab == .home {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    isShowingProfileSheet = true
                                } label: {
                                    Image(systemName: "person.crop.circle")
                                        .font(.title3)
                                }
                                .accessibilityLabel("Buka Profil")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Beranda", systemImage: "house.fill")
            }
            .tag(MainTab.home)

            NavigationStack {
                PlantScanView()
            }
            .tabItem {
                Label("Lapor", systemImage: "camera.fill")
            }
            .tag(MainTab.plantScan)

            NavigationStack {
                RadarFeedView()
            }
            .tabItem {
                Label("Radar Feed", systemImage: "dot.radiowaves.left.and.right")
            }
            .tag(MainTab.radarFeed)

            NavigationStack {
                RadarMapView()
            }
            .tabItem {
                Label("Peta", systemImage: "map.fill")
            }
            .tag(MainTab.map)
        }
        .tint(RTDColor.deepGreen)
        .sheet(isPresented: $isShowingProfileSheet) {
            NavigationStack {
                ProfileView(userEmail: userEmail) {
                    isShowingProfileSheet = false
                    onLogout()
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
