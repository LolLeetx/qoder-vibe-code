import SwiftUI

struct BattleArenaView: View {
    @EnvironmentObject var battleVM: BattleViewModel
    @State private var showMoves = true
    @State private var showSwitchMenu = false

    var body: some View {
        if let battle = battleVM.currentBattle {
            VStack(spacing: 0) {
                // Opponent side
                opponentSection(battle)

                // VS divider
                HStack {
                    Rectangle().fill(PixelColors.cardBorder).frame(height: 1)
                    PixelText(text: "VS", size: 14, color: PixelColors.danger)
                        .padding(.horizontal, 8)
                    Rectangle().fill(PixelColors.cardBorder).frame(height: 1)
                }
                .padding(.vertical, 4)

                // Player side
                playerSection(battle)

                // Battle log
                battleLog(battle)

                Spacer(minLength: 0)

                // Action buttons
                if battleVM.battlePhase == .fighting {
                    actionPanel(battle)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Opponent Section

    private func opponentSection(_ battle: Battle) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    PixelText(text: battle.player2Active.name, size: 14, color: .white)
                    Spacer()
                    PixelText(text: "Lv.\(battle.player2Active.level)", size: 11, color: .gray)
                }
                HPBar(currentHP: battle.player2Active.stats.hp, maxHP: battle.player2Active.stats.maxHP, height: 10)
                HStack(spacing: 4) {
                    TypeBadge(category: battle.player2Active.category, small: true)
                    Spacer()
                    // Team indicators
                    HStack(spacing: 3) {
                        ForEach(0..<battle.player2Team.count, id: \.self) { i in
                            Circle()
                                .fill(battle.player2Team[i].isFainted ? Color.gray.opacity(0.3) : PixelColors.danger)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }

            CreatureSpriteView(creature: battle.player2Active, size: 72)
                .offset(x: battleVM.shakePlayer2 ? 8 : 0)
                .animation(.default.repeatCount(3, autoreverses: true).speed(4), value: battleVM.shakePlayer2)
        }
        .padding(12)
        .background(PixelColors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Player Section

    private func playerSection(_ battle: Battle) -> some View {
        HStack(spacing: 12) {
            CreatureSpriteView(creature: battle.player1Active, size: 80)
                .offset(x: battleVM.shakePlayer1 ? -8 : 0)
                .animation(.default.repeatCount(3, autoreverses: true).speed(4), value: battleVM.shakePlayer1)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    PixelText(text: battle.player1Active.name, size: 14, color: .white)
                    Spacer()
                    PixelText(text: "Lv.\(battle.player1Active.level)", size: 11, color: .gray)
                }
                HPBar(currentHP: battle.player1Active.stats.hp, maxHP: battle.player1Active.stats.maxHP, height: 10)
                HStack(spacing: 4) {
                    TypeBadge(category: battle.player1Active.category, small: true)
                    Spacer()
                    HStack(spacing: 3) {
                        ForEach(0..<battle.player1Team.count, id: \.self) { i in
                            Circle()
                                .fill(battle.player1Team[i].isFainted ? Color.gray.opacity(0.3) : PixelColors.success)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(PixelColors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Battle Log

    private func battleLog(_ battle: Battle) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(battleVM.lastLogMessages.enumerated()), id: \.offset) { idx, msg in
                        logLine(msg)
                            .id(idx)
                    }
                }
                .padding(8)
            }
            .frame(height: 100)
            .background(Color.black.opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(PixelColors.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onChange(of: battleVM.lastLogMessages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(battleVM.lastLogMessages.count - 1, anchor: .bottom)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func logLine(_ msg: String) -> some View {
        let color: Color = {
            if msg.contains("Super effective") { return PixelColors.gold }
            if msg.contains("Not very effective") { return .gray }
            if msg.contains("damage") { return PixelColors.danger }
            if msg.contains("fainted") { return PixelColors.danger }
            if msg.contains("wins") { return PixelColors.gold }
            return .white.opacity(0.8)
        }()

        return Text(msg)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(color)
    }

    // MARK: - Action Panel

    private func actionPanel(_ battle: Battle) -> some View {
        VStack(spacing: 8) {
            if !battleVM.isPlayerTurn {
                HStack {
                    ProgressView()
                        .tint(.white)
                    PixelText(
                        text: battleVM.waitingForOpponent ? "Waiting for opponent..." : "Opponent's turn...",
                        size: 12,
                        color: .gray
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else if showSwitchMenu {
                switchMenu(battle)
            } else {
                moveButtons(battle)
                HStack(spacing: 8) {
                    if battle.player1Team.filter({ !$0.isFainted }).count > 1 {
                        PixelButton(title: "SWITCH", color: PixelColors.xpBar) {
                            showSwitchMenu = true
                        }
                    }
                    PixelButton(title: "FORFEIT", color: PixelColors.danger.opacity(0.7), textColor: .white) {
                        battleVM.forfeit()
                    }
                }
            }
        }
        .frame(minHeight: 120)
        .padding(.vertical, 8)
    }

    private func moveButtons(_ battle: Battle) -> some View {
        let creature = battle.player1Active
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(Array(creature.moves.enumerated()), id: \.offset) { idx, move in
                Button(action: {
                    battleVM.playerSelectMove(idx)
                }) {
                    VStack(spacing: 2) {
                        PixelText(text: move.name, size: 11, color: .white)
                        HStack(spacing: 4) {
                            TypeBadge(category: move.type, small: true)
                            PixelText(text: "PWR \(move.power)", size: 9, color: .gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(move.type.color.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(move.type.color.opacity(0.5), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .disabled(!battleVM.isPlayerTurn)
            }
        }
    }

    private func switchMenu(_ battle: Battle) -> some View {
        VStack(spacing: 8) {
            HStack {
                PixelText(text: "Switch to:", size: 12, color: .gray)
                Spacer()
                Button(action: { showSwitchMenu = false }) {
                    PixelText(text: "BACK", size: 10, color: PixelColors.accent)
                }
            }
            ForEach(Array(battle.player1Team.enumerated()), id: \.offset) { idx, creature in
                if idx != battle.player1ActiveIndex && !creature.isFainted {
                    Button(action: {
                        battleVM.playerSwitchCreature(idx)
                        showSwitchMenu = false
                    }) {
                        HStack {
                            CreatureSpriteView(creature: creature, size: 32)
                            PixelText(text: creature.name, size: 12, color: .white)
                            Spacer()
                            HPBar(currentHP: creature.stats.hp, maxHP: creature.stats.maxHP, height: 8, showLabel: false)
                                .frame(width: 80)
                        }
                        .padding(8)
                        .background(creature.category.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }
}

// MARK: - Battle Result

struct BattleResultView: View {
    @EnvironmentObject var battleVM: BattleViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var didUpdateLeaderboard = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                if battleVM.playerWon {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56))
                        .foregroundColor(PixelColors.gold)
                    PixelText(text: "VICTORY!", size: 32, color: PixelColors.gold)
                } else {
                    Image(systemName: "xmark.shield.fill")
                        .font(.system(size: 56))
                        .foregroundColor(PixelColors.danger)
                    PixelText(text: "DEFEAT", size: 32, color: PixelColors.danger)
                }

                PixelText(text: battleVM.playerWon ? "Your creatures fought bravely!" : "Better luck next time!", size: 14, color: .gray)

                PixelButton(title: "CONTINUE", color: PixelColors.accent) {
                    battleVM.resetBattle()
                }
            }
            .padding(32)
            .background(PixelColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(battleVM.playerWon ? PixelColors.gold : PixelColors.danger, lineWidth: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(40)
            .onAppear {
                if !didUpdateLeaderboard {
                    didUpdateLeaderboard = true
                    authVM.updateLeaderboard(won: battleVM.playerWon)
                }
            }
        }
    }
}
