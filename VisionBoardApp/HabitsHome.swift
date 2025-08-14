// HabitsHome.swift
import SwiftUI

struct HabitsHome: View {
    let userId: String
    @StateObject private var vm = HabitsListVM()
    @State private var showingAdd = false
    @State private var newName = ""

    var body: some View {
        List {
            if vm.habits.isEmpty {
                Text("No habits yet. Tap + to add one.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.habits) { habit in
                    NavigationLink(destination: HabitDetailPlaceholder(habit: habit)) {
                        HStack {
                            Text(habit.name).font(.headline)
                            Spacer()
                            Text(habit.createdAt, style: .date)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Your Habits")
        .toolbar { Button { showingAdd = true } label: { Image(systemName: "plus") } }
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
        } message: { Text("Give your habit a name.") }
    }
}

struct HabitDetailPlaceholder: View {
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
