import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        print("🔥 Firebase configured")

        // Ensure an anonymous session is created immediately
        signInAnonymouslyIfNeeded()

        return true
    }
}

@main
struct VisionBoardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            AppRouter()
        }
    }
}

// MARK: - Auth helper
func signInAnonymouslyIfNeeded() {
    if Auth.auth().currentUser == nil {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                print("🚨 Anonymous sign-in failed: \(error.localizedDescription)")
            } else if let user = result?.user {
                print("✅ Signed in anonymously as: \(user.uid)")
            }
        }
    } else {
        print("Already signed in as: \(Auth.auth().currentUser?.uid ?? "unknown")")
    }
}
