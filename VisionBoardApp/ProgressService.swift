import FirebaseFirestore

struct DailyProgress {
    let completed: Int
    let total: Int
}

enum ProgressService {
    static func getTodayProgress(userId: String) async throws -> DailyProgress {
        let db = Firestore.firestore()
        let habitsRef = db.collection("users").document(userId).collection("habits")
        let habitsSnapshot = try await habitsRef.getDocuments()

        let todayKey = todayDateString()
        var completed = 0

        for doc in habitsSnapshot.documents {
            let habitId = doc.documentID
            let completionRef = habitsRef.document(habitId).collection("completions").document(todayKey)
            let completionDoc = try await completionRef.getDocument()
            if completionDoc.exists {
                completed += 1
            }
        }
        
        let progressRef = db.collection("users").document(userId)
            .collection("dailyProgress").document(todayKey)

        try await progressRef.setData([
            "completed": completed,
            "total": habitsSnapshot.count,
            "timestamp": Timestamp(date: Date())
        ])

        return DailyProgress(completed: completed, total: habitsSnapshot.count)
    }
}

func todayDateString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    return formatter.string(from: Date())
}
