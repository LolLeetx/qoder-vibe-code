import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct TaskMonApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authVM = AuthViewModel()
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var creatureVM = CreatureViewModel()
    @StateObject private var battleVM = BattleViewModel()

    init() {}

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isSignedIn {
                    MainTabView()
                        .environmentObject(taskVM)
                        .environmentObject(creatureVM)
                        .environmentObject(battleVM)
                        .environmentObject(authVM)
                        .onAppear {
                            creatureVM.linkTaskVM(taskVM)
                        }
                } else {
                    LoginView()
                        .environmentObject(authVM)
                }
            }
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.3), value: authVM.isSignedIn)
            .onAppear {
                authVM.onSignIn = { [weak taskVM, weak creatureVM] userId in
                    taskVM?.setUser(userId)
                    creatureVM?.setUser(userId)
                    XPManager.shared.setUser(userId)
                }
                authVM.onSignOut = { [weak taskVM, weak creatureVM] in
                    taskVM?.clearData()
                    creatureVM?.clearData()
                    XPManager.shared.clearData()
                }
            }
        }
    }
}
