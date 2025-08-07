import SwiftUI
import FirebaseCore
import FirebaseAuth


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}


@main
struct VisionBoardApp: App {
    // Initialize Firebase as soon as the app launches
    init() {
        FirebaseApp.configure()
        signInAnonymouslyIfNeeded()
    }

    
    var body: some Scene {
      WindowGroup {
        MainMenuView()
      }
    }
}

func signInAnonymouslyIfNeeded() {
    if Auth.auth().currentUser == nil {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                print("Anonymous sign-in failed: \(error.localizedDescription)")
            } else {
                print("Signed in anonymously as: \(result?.user.uid ?? "unknown")")
            }
        }
    } else {
        print("Already signed in: \(Auth.auth().currentUser?.uid ?? "unknown")")
    }
}
