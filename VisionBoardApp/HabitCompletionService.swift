import FirebaseFirestore

enum HabitCompletionService {
    static func listenIsDoneToday(
        userId: String,
        habitId: String,
        onChange: @escaping (Bool) -> Void
    ) -> ListenerRegistration {
        let todayKey = Self.todayKey()
        let ref = Firestore.firestore()
            .collection("users").document(userId)
            .collection("habits").document(habitId)
            .collection("completions").document(todayKey)

        return ref.addSnapshotListener { snap, _ in
            onChange(snap?.exists == true)
        }
    }

    static func markDoneToday(userId: String, habitId: String, photoUrl: String? = nil) async throws {
        let todayKey = Self.todayKey()
        let ref = Firestore.firestore()
            .collection("users").document(userId)
            .collection("habits").document(habitId)
            .collection("completions").document(todayKey)

        var data: [String: Any] = [
            "doneAt": Date()
        ]
        if let photoUrl {
            data["photoUrl"] = photoUrl
        }

        try await ref.setData(data)
    }

    static func unmarkDoneToday(userId: String, habitId: String) async throws {
        let todayKey = Self.todayKey()
        let ref = Firestore.firestore()
            .collection("users").document(userId)
            .collection("habits").document(habitId)
            .collection("completions").document(todayKey)
        try await ref.delete()
    }

    private static func todayKey() -> String {
        let f = DateFormatter()
        f.calendar = .current
        f.locale = .current
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
