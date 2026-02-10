import SwiftUI

struct BattleView: View {
    @EnvironmentObject var battleVM: BattleViewModel
    @EnvironmentObject var creatureVM: CreatureViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                PixelColors.background.ignoresSafeArea()

                switch battleVM.battlePhase {
                case .setup:
                    if battleVM.isMatchmaking {
                        MatchmakingView()
                            .environmentObject(battleVM)
                    } else {
                        BattleSetupView()
                            .environmentObject(battleVM)
                            .environmentObject(creatureVM)
                    }
                case .fighting:
                    if let _ = battleVM.currentBattle {
                        BattleArenaView()
                            .environmentObject(battleVM)
                    }
                case .finished:
                    if let _ = battleVM.currentBattle {
                        BattleArenaView()
                            .environmentObject(battleVM)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PixelTitle(text: "BATTLE", color: PixelColors.danger)
                }
            }
            .overlay {
                if battleVM.showBattleResult {
                    BattleResultView()
                        .environmentObject(battleVM)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .animation(.spring(response: 0.4), value: battleVM.showBattleResult)
        }
    }
}
