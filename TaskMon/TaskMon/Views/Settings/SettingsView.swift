import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                PixelColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Profile card
                        profileCard

                        // Stats card
                        statsCard

                        // App info
                        appInfoCard

                        // Sign out
                        PixelButton(title: "SIGN OUT", color: PixelColors.danger, textColor: .white) {
                            showSignOutAlert = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PixelTitle(text: "SETTINGS", color: PixelColors.accent)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authVM.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    private var profileCard: some View {
        PixelCard {
            HStack(spacing: 16) {
                // Avatar
                if let photoURL = authVM.currentPlayer?.photoURL ?? authVM.authInfo.photoURL,
                   let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(PixelColors.accent, lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.gray)
                        .frame(width: 56, height: 56)
                }

                VStack(alignment: .leading, spacing: 4) {
                    PixelText(
                        text: authVM.currentPlayer?.displayName ?? authVM.authInfo.displayName ?? "Trainer",
                        size: 16,
                        color: .white
                    )
                    .lineLimit(1)

                    if let email = authVM.currentPlayer?.email ?? authVM.authInfo.email {
                        Text(email)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
        }
    }

    private var statsCard: some View {
        PixelCard {
            VStack(spacing: 12) {
                HStack {
                    PixelText(text: "BATTLE STATS", size: 13, color: PixelColors.gold)
                    Spacer()
                }

                HStack(spacing: 16) {
                    statItem(
                        icon: "trophy.fill",
                        label: "Wins",
                        value: "\(authVM.currentPlayer?.wins ?? 0)",
                        color: PixelColors.success
                    )
                    statItem(
                        icon: "xmark.shield.fill",
                        label: "Losses",
                        value: "\(authVM.currentPlayer?.losses ?? 0)",
                        color: PixelColors.danger
                    )
                    statItem(
                        icon: "bolt.fill",
                        label: "Total XP",
                        value: "\(authVM.currentPlayer?.totalXP ?? 0)",
                        color: PixelColors.xpBar
                    )
                }
            }
        }
    }

    private func statItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            PixelText(text: value, size: 16, color: .white)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var appInfoCard: some View {
        PixelCard {
            VStack(spacing: 8) {
                HStack {
                    PixelText(text: "APP INFO", size: 13, color: PixelColors.accent)
                    Spacer()
                }

                infoRow(label: "Version", value: "1.0.0")
                infoRow(label: "Build", value: "1")
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

// Expose auth info for SettingsView to access display info
extension AuthViewModel {
    var authInfo: AuthServiceProtocol {
        ServiceContainer.shared.auth
    }
}
