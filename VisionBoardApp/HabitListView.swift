import SwiftUI
import FirebaseFirestore

// MARK: - Model
struct Habit: Identifiable, Hashable {
    let id: String
    let name: String
    let createdAt: Date
}

// MARK: - ViewModel
@MainActor
final class HabitsListVM: ObservableObject {
    @Published var habits: [Habit] = []
    private var listener: ListenerRegistration?

    func start(userId: String) {
        listener?.remove()

        let ref = Firestore.firestore()
            .collection("users").document(userId)
            .collection("habits")
            .order(by: "createdAt", descending: true)

        listener = ref.addSnapshotListener { [weak self] snap, err in
            guard err == nil, let docs = snap?.documents else {
                print("Habits listener error:", err?.localizedDescription ?? "nil")
                self?.habits = []
                return
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

    func addHabit(userId: String, name: String) async {
        let ref = Firestore.firestore()
            .collection("users").document(userId)
            .collection("habits").document()

        let payload: [String: Any] = [
            "name": name,
            "createdAt": Date()
        ]

        do { try await ref.setData(payload) }
        catch { print("addHabit error:", error) }
    }
}

// MARK: - View
struct HabitsListView: View {
    let userId: String

    @StateObject private var vm = HabitsListVM()
    @State private var showingAdd = false
    @State private var newName = ""

    var body: some View {
        // Assume we're already inside a NavigationStack upstream
        content
            .navigationTitle("Your Habits")
            .toolbar { addButton }
            .onAppear { vm.start(userId: userId) }
            .onDisappear { vm.stop() }
            .alert("New Habit", isPresented: $showingAdd) {
                TextField("Name", text: $newName)
                Button("Add") {
                    let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    newName = ""
                    Task { await vm.addHabit(userId: userId, name: name.isEmpty ? "Untitled Habit" : name) }
                }
                Button("Cancel", role: .cancel) { newName = "" }
            } message: {
                Text("Give your habit a name.")
            }
    }

    @ViewBuilder
    private var content: some View {
        if vm.habits.isEmpty {
            EmptyState()
        } else {
            List {
                ForEach(vm.habits) { habit in
                    NavigationLink(
                        destination: HabitDetailPlaceholder(habit: habit)
                    ) {
                        HabitRow(habit: habit)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingAdd = true } label: { Image(systemName: "plus") }
                .accessibilityLabel("Add Habit")
        }
    }
}

// MARK: - Small subviews (keep the compiler happy)
private struct EmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("No habits yet").font(.headline).foregroundStyle(.secondary)
            Text("Tap + to add your first habit.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HabitRow: View {
    let habit: Habit
    var body: some View {
        HStack {
            Text(habit.name).font(.headline)
            Spacer()
            Text(habit.createdAt, style: .date)
                .font(.caption).foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }
}

// Placeholder detail until you wire the collage/progress view
private struct HabitDetailPlaceholder: View {
    let habit: Habit
    var body: some View {
        VStack(spacing: 12) {
            Text(habit.name).font(.largeTitle)
            ProgressView(value: 0.4)
            Text("Collage goes here…").foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(habit.name)
    }
}
