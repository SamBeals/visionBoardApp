import FirebaseFirestore
import FirebaseAuth

func createHabit(named name: String, completion: @escaping (Error?) -> Void) {
    let userId = UserSessionHelper.userId


    let db = Firestore.firestore()
    let habitRef = db.collection("users")
        .document(userId)
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
