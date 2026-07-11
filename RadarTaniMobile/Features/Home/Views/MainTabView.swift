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
    @Environment(PlantAnalysisStore.self) private var plantAnalysisStore

    let userEmail: String
    let reportHistoryStore: ReportHistoryStore
    let onLogout: () -> Void

    @State private var selectedTab: MainTab = .home
    @State private var isShowingProfileSheet = false
    @State private var plantScanPath: [PlantScanRoute] = []

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

            NavigationStack(path: $plantScanPath) {
                PlantScanView(selectedTab: $selectedTab, path: $plantScanPath)
                    .navigationDestination(for: PlantScanRoute.self) { route in
                        plantScanDestination(for: route)
                    }
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
        .fullScreenCover(isPresented: $isShowingProfileSheet) {
            NavigationStack {
                ProfileView(userEmail: userEmail, reportHistoryStore: reportHistoryStore) {
                    isShowingProfileSheet = false
                    onLogout()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingProfileSheet = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Tutup Profil")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func plantScanDestination(for route: PlantScanRoute) -> some View {
        switch route {
        case .compose:
            if let image = plantAnalysisStore.pendingImage {
                CreatePlantReportView(image: image, path: $plantScanPath)
            } else {
                ContentUnavailableView(
                    "Foto tidak tersedia",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("Kembali ke Lapor dan pilih foto tanaman lagi.")
                )
            }
        case .processing(let taskID):
            PlantAnalysisProcessingView(taskID: taskID, path: $plantScanPath)
        case .tasks:
            PlantAnalysisTaskListView(path: $plantScanPath)
        case .result(let taskID):
            PlantDiagnosisResultView(
                taskID: taskID,
                reportHistoryStore: reportHistoryStore,
                path: $plantScanPath
            )
        case .chat(let taskID):
            PlantAIChatView(taskID: taskID)
        case .success(let taskID):
            PlantReportSuccessView(taskID: taskID, path: $plantScanPath)
        }
    }
}
