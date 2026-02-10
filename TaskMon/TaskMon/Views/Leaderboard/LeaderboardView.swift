import SwiftUI

struct LeaderboardView: View {
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @EnvironmentObject var authVM: AuthViewModel

    private let dbService = ServiceContainer.shared.database

    var body: some View {
        NavigationStack {
            ZStack {
                PixelColors.background.ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(PixelColors.accent)
                        PixelText(text: "Loading rankings...", size: 13, color: .gray)
                    }
                } else if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.4))
                        PixelText(text: "No rankings yet", size: 16, color: .gray)
                        PixelText(text: "Win online battles to appear here!", size: 12, color: .gray.opacity(0.7))
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(PixelColors.danger)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.top, 4)
                            Button(action: { Task { await loadLeaderboard() } }) {
                                PixelText(text: "RETRY", size: 12, color: PixelColors.accent)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(PixelColors.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                leaderboardRow(rank: index + 1, entry: entry)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PixelTitle(text: "LEADERBOARD", color: PixelColors.gold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await loadLeaderboard() } }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(PixelColors.accent)
                    }
                }
            }
            .task {
                await loadLeaderboard()
            }
        }
    }

    private func leaderboardRow(rank: Int, entry: LeaderboardEntry) -> some View {
        let isMe = entry.id == authVM.currentPlayer?.id

        return HStack(spacing: 12) {
            // Rank
            rankBadge(rank)

            // Avatar
            if let photoURL = entry.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
                    .frame(width: 36, height: 36)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    PixelText(text: entry.displayName, size: 13, color: .white)
                        .lineLimit(1)
                    if isMe {
                        Text("(You)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(PixelColors.accent)
                    }
                }
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 8))
                            .foregroundColor(PixelColors.accent)
                        Text("\(entry.creatureCount)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    HStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(PixelColors.xpBar)
                        Text("\(entry.totalXP) XP")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            // Win/Loss
            VStack(alignment: .trailing, spacing: 2) {
                PixelText(text: "\(entry.wins)W / \(entry.losses)L", size: 11, color: .white)
                PixelText(
                    text: String(format: "%.0f%%", entry.winRate),
                    size: 10,
                    color: entry.winRate >= 50 ? PixelColors.success : PixelColors.danger
                )
            }
        }
        .padding(10)
        .background(isMe ? PixelColors.accent.opacity(0.1) : PixelColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isMe ? PixelColors.accent.opacity(0.5) : PixelColors.cardBorder, lineWidth: isMe ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func rankBadge(_ rank: Int) -> some View {
        let color: Color = {
            switch rank {
            case 1: return PixelColors.gold
            case 2: return Color(white: 0.75)
            case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
            default: return .gray
            }
        }()

        return ZStack {
            if rank <= 3 {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            Text("\(rank)")
                .font(.system(size: rank <= 3 ? 9 : 12, weight: .bold, design: .monospaced))
                .foregroundColor(rank <= 3 ? .black : .white)
                .offset(y: rank <= 3 ? 1 : 0)
        }
        .frame(width: 28, height: 28)
    }

    private func loadLeaderboard() async {
        isLoading = true
        errorMessage = nil
        do {
            entries = try await dbService.loadLeaderboard(limit: 50)
        } catch {
            print("Leaderboard error: \(error)")
            let desc = error.localizedDescription
            if desc.contains("permissions") {
                errorMessage = "Firestore rules need updating. Deploy firestore.rules via Firebase CLI or update rules in Firebase Console."
            } else {
                errorMessage = desc
            }
        }
        isLoading = false
    }
}
