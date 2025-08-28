import SwiftUI
import FirebaseFirestore

struct TodoItem: Identifiable, Hashable {
    let id: String
    let title: String
    let createdAt: Date
    let doneOn: String?
}

@MainActor
final class ToDoListVM: ObservableObject {
    @Published var items: [TodoItem] = []
    private var listener: ListenerRegistration?

    func start(userId: String) {
        listener?.remove()
        let ref = Firestore.firestore()
            .collection("users").document(userId)
            .collection("todos")
            .order(by: "createdAt", descending: false)

        listener = ref.addSnapshotListener { [weak self] snap, err in
            guard err == nil, let docs = snap?.documents else { self?.items = []; return }
            self?.items = docs.compactMap { d in
                let data = d.data()
                guard let title = data["title"] as? String else { return nil }
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                    ?? (data["createdAt"] as? Date) ?? Date()
                let doneOn = data["doneOn"] as? String
                return TodoItem(id: d.documentID, title: title, createdAt: createdAt, doneOn: doneOn)
            }
        }
    }

    func stop() { listener?.remove(); listener = nil }

    func add(userId: String, title: String) async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let ref = Firestore.firestore()
            .collection("users").document(userId)
            .collection("todos").document()
        try? await ref.setData([
            "title": trimmed,
            "createdAt": Date()
        ])
    }

    func setDone(userId: String, item: TodoItem, isDoneToday: Bool) async {
        let ref = Firestore.firestore()
            .collection("users").document(userId)
            .collection("todos").document(item.id)
        let today = Self.todayKey()
        if isDoneToday {
            try? await ref.updateData(["doneOn": today])
        } else {
            try? await ref.updateData(["doneOn": FieldValue.delete()])
        }
    }

    // 🚨 NEW: delete function
    func delete(userId: String, item: TodoItem) async {
        let ref = Firestore.firestore()
            .collection("users").document(userId)
            .collection("todos").document(item.id)
        try? await ref.delete()
    }

    static func todayKey() -> String {
        let f = DateFormatter()
        f.calendar = .current; f.locale = .current; f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

struct ToDoListView: View {
    let userId: String
    @StateObject private var vm = ToDoListVM()
    @State private var newTitle = ""

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("New to-do", text: $newTitle)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit { add() }

                    Button("Add") { add() }
                        .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()

                if vm.items.isEmpty {
                    VStack(spacing: 8) {
                        Text("No to-dos yet").font(.headline).foregroundStyle(.secondary)
                        Text("Add something you want to get done today.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.items) { item in
                            TodoRow(
                                item: item,
                                isDoneToday: item.doneOn == ToDoListVM.todayKey(),
                                toggle: { checked in
                                    Task { await vm.setDone(userId: userId, item: item, isDoneToday: checked) }
                                }
                            )
                        }
                        // 🚨 NEW: swipe-to-delete support
                        .onDelete { indexSet in
                            for index in indexSet {
                                let item = vm.items[index]
                                Task { await vm.delete(userId: userId, item: item) }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("To-Do")
        }
        .onAppear { vm.start(userId: userId) }
        .onDisappear { vm.stop() }
    }

    private func add() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        Task { await vm.add(userId: userId, title: title) }
        newTitle = ""
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let isDoneToday: Bool
    let toggle: (Bool) -> Void

    var body: some View {
        HStack {
            Button { toggle(!isDoneToday) } label: {
                Image(systemName: isDoneToday ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)

            Text(item.title)
                .strikethrough(isDoneToday, color: .secondary)
                .foregroundStyle(isDoneToday ? .secondary : .primary)

            Spacer()
            Text(item.createdAt, style: .date)
                .font(.caption).foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { toggle(!isDoneToday) }
    }
}
