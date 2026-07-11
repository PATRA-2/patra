import SwiftUI

enum MainTab: Hashable {
    case home
    case farms
    case plantScan
    case radarFeed
    case map
}

typealias HomeTab = MainTab

extension MainTab {
    static let report: MainTab = .plantScan
}

struct MainTabView: View {
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
                FarmListView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Lahan", systemImage: "leaf.fill")
            }
            .tag(MainTab.farms)

            PlantScanView(selectedTab: $selectedTab)
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
                ProfileView(onLogout: {
                    isShowingProfileSheet = false
                    onLogout()
                })
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}
