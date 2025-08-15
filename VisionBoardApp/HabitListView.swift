import SwiftUI
import FirebaseFirestore

// MARK: - Model
struct Habit: Identifiable, Hashable {
    let id: String
    let name: String
    let createdAt: Date
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
