import SwiftUI
import FirebaseFirestore

@MainActor
final class HabitsListVM: ObservableObject {
    @Published var habits: [Habit] = []
    private var listener: ListenerRegistration?

    func start() {
        listener?.remove()
        let ref = Firestore.firestore()
            .collection("users").document(UserSessionHelper.userId)
            .collection("habits")
            .order(by: "createdAt", descending: true)

        listener = ref.addSnapshotListener { [weak self] snap, err in
            guard err == nil, let docs = snap?.documents else {
                self?.habits = []; return
            }
            self?.habits = docs.compactMap { d in
                let data = d.data()
                guard let name = data["name"] as? String else { return nil }
                let createdAt: Date =
                    (data["createdAt"] as? Timestamp)?.dateValue() ??
                    (data["createdAt"] as? Date) ?? Date()
                return Habit(id: d.documentID, name: name, createdAt: createdAt)
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func addHabit(name: String) async {
        let ref = Firestore.firestore()
            .collection("users").document(UserSessionHelper.userId)
            .collection("habits").document()
        try? await ref.setData([
            "name": name,
            "createdAt": Date()
        ])
    }
    func deleteHabit(habit: Habit) async {
        let ref = Firestore.firestore()
            .collection("users").document(UserSessionHelper.userId)
            .collection("habits").document(habit.id)
        try? await ref.delete()
    }
}


