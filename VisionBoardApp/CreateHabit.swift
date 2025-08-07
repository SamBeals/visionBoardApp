import FirebaseFirestore
import FirebaseAuth

func createHabit(named name: String, completion: @escaping (Error?) -> Void) {
    guard let userID = Auth.auth().currentUser?.uid else {
        print("No user signed in.")
        completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in"]))
        return
    }

    let db = Firestore.firestore()
    let habitRef = db.collection("users")
        .document(userID)
        .collection("habits")
        .document() // auto-ID

    let data: [String: Any] = [
        "name": name,
        "createdAt": FieldValue.serverTimestamp(),
        "logs": [:]  // empty dictionary to hold daily check-ins
    ]

    habitRef.setData(data) { error in
        if let error = error {
            print("Error creating habit: \(error.localizedDescription)")
            completion(error)
        } else {
            print("Habit successfully created.")
            completion(nil)
        }
    }
}
