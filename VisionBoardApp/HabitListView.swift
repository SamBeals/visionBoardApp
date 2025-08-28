// HabitsListView.swift
import SwiftUI

struct HabitsListView: View {
    let userId: String
    @StateObject private var viewModel = HabitsListVM()

    @State private var showingAdd = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            if viewModel.habits.isEmpty {
                VStack(spacing: 12) {
                    Text("No habits yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Tap + to add your first habit.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.habits) { habit in
                        NavigationLink(
                            destination: HabitDetailView(habit: habit)
                        ) {
                            HStack {
                                Text(habit.name).font(.headline)
                                Spacer()
                                Text(habit.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    // 🚨 NEW: swipe-to-delete
                    .onDelete { indexSet in
                        for index in indexSet {
                            let habit = viewModel.habits[index]
                            Task {
                                await viewModel.deleteHabit(habit: habit)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Your Habits")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .alert("New Habit", isPresented: $showingAdd) {
            TextField("Name", text: $newName)
            Button("Add") {
                let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                newName = ""
                Task {
                    await viewModel.addHabit(
                        name: name.isEmpty ? "Untitled Habit" : name
                    )
                }
            }
            Button("Cancel", role: .cancel) { newName = "" }
        } message: {
            Text("Give your habit a name.")
        }
    }
}
