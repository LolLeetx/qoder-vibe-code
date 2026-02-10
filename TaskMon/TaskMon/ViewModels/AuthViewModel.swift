import Foundation
import SwiftUI
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentPlayer: Player?

    private let authService = ServiceContainer.shared.auth
    private let dbService = ServiceContainer.shared.database

    init() {
        // Check if already signed in from a previous session
        if let uid = authService.currentUserId, authService.isAuthenticated {
            isSignedIn = true
            Task { await loadPlayer(userId: uid) }
        }
    }

    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Cannot find root view controller"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let uid = try await authService.signInWithGoogle(presenting: rootVC)
                await loadOrCreatePlayer(userId: uid)
                isSignedIn = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func continueAsGuest() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let uid = try await authService.signInAnonymously()
                let player = Player(
                    id: uid,
                    username: "Guest",
                    displayName: "Guest",
                    email: nil,
                    photoURL: nil
                )
                currentPlayer = player
                try await dbService.savePlayer(player)
                isSignedIn = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            isSignedIn = false
            currentPlayer = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadOrCreatePlayer(userId: String) async {
        do {
            if let existing = try await dbService.loadPlayer(userId: userId) {
                currentPlayer = existing
                // Update display info from auth in case it changed
                currentPlayer?.displayName = authService.displayName ?? existing.displayName
                currentPlayer?.email = authService.email
                currentPlayer?.photoURL = authService.photoURL
                try await dbService.savePlayer(currentPlayer!)
            } else {
                let player = Player(
                    id: userId,
                    username: authService.displayName ?? "Trainer",
                    displayName: authService.displayName ?? "Trainer",
                    email: authService.email,
                    photoURL: authService.photoURL
                )
                currentPlayer = player
                try await dbService.savePlayer(player)
            }
            // Update leaderboard entry
            if let player = currentPlayer {
                let entry = player.toLeaderboardEntry(creatureCount: player.creatures.count)
                try await dbService.saveLeaderboardEntry(entry)
            }
        } catch {
            print("Error loading/creating player: \(error)")
        }
    }

    private func loadPlayer(userId: String) async {
        do {
            currentPlayer = try await dbService.loadPlayer(userId: userId)
            if currentPlayer == nil {
                // First launch after auth restore - create from auth info
                await loadOrCreatePlayer(userId: userId)
            }
        } catch {
            print("Error loading player: \(error)")
        }
    }

    func updateLeaderboard(won: Bool) {
        guard var player = currentPlayer else { return }
        if won { player.wins += 1 } else { player.losses += 1 }
        currentPlayer = player

        Task {
            do {
                try await dbService.savePlayer(player)
            } catch {
                print("[Leaderboard] Failed to save player: \(error)")
            }
            do {
                let entry = player.toLeaderboardEntry(creatureCount: player.creatures.count)
                try await dbService.saveLeaderboardEntry(entry)
            } catch {
                print("[Leaderboard] Failed to save leaderboard entry: \(error)")
            }
        }
    }
}
