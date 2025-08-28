import Foundation
import FirebaseAuth

enum UserSessionHelper {
    // 🔒 For now, hardcode a fixed UID
    static let userId = "L1D1xpv24IUwBQqAg1wPD2D3Xq93"

    // Later, when you want real auth again:
    static var current: String? {
        return Auth.auth().currentUser?.uid
    }
}
