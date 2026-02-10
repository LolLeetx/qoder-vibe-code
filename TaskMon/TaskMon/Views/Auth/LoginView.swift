import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            PixelColors.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 12) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [PixelColors.accent, PixelColors.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    PixelText(text: "TASKMON", size: 36, color: PixelColors.accent)
                        .offset(y: titleOffset)
                        .opacity(logoOpacity)

                    PixelText(text: "Complete tasks. Collect creatures. Battle!", size: 13, color: .gray)
                        .offset(y: titleOffset)
                        .opacity(logoOpacity)
                }

                Spacer()

                // Sign in section
                VStack(spacing: 16) {
                    // Google Sign-In button
                    Button(action: {
                        authVM.signInWithGoogle()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)

                            Text("Sign in with Google")
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.26, green: 0.52, blue: 0.96), Color(red: 0.2, green: 0.4, blue: 0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(authVM.isLoading)

                    if authVM.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            PixelText(text: "Signing in...", size: 12, color: .gray)
                        }
                    }

                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(PixelColors.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .opacity(buttonOpacity)
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                titleOffset = 0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.7)) {
                buttonOpacity = 1.0
            }
        }
    }
}
