import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(0)

            CreaturesView()
                .tabItem {
                    Label("Creatures", systemImage: "pawprint.fill")
                }
                .tag(1)

            BattleView()
                .tabItem {
                    Label("Battle", systemImage: "shield.lefthalf.filled")
                }
                .tag(2)

            LeaderboardView()
                .tabItem {
                    Label("Ranks", systemImage: "trophy.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(PixelColors.accent)
    }
}
