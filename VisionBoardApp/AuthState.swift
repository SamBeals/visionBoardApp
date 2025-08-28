// AppRouter.swift
import SwiftUI
import FirebaseAuth

@MainActor
final class AuthState: ObservableObject {
    @Published var user: User? = Auth.auth().currentUser
    private var h: AuthStateDidChangeListenerHandle?

    init() {
        h = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }
    deinit { if let h { Auth.auth().removeStateDidChangeListener(h) } }

    func ensureAnonymous() async {
        guard Auth.auth().currentUser == nil else { return }
        _ = try? await Auth.auth().signInAnonymously()
    }
}

struct AppRouter: View {
    @StateObject private var auth = AuthState()
    var body: some View {
        Group {
            if let user = auth.user {
                MainMenuView()
            } else {
                ProgressView("Loading…")
                    .task { await auth.ensureAnonymous() }
            }
        }
    }
}

