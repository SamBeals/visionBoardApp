import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct ToDoListView: View {
    @State private var selectedScope = "Daily"
    @State private var newTaskText = ""
    @State private var tasks: [ToDoTask] = []

    private let scopes = ["Daily", "Weekly", "Monthly"]
    private var uid: String? { Auth.auth().currentUser?.uid }

    var body: some View {
        VStack {
            Text("To-Do List")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            // Scope selector (daily, weekly, monthly)
            Picker("Scope", selection: $selectedScope) {
                ForEach(scopes, id: \.self) { scope in
                    Text(scope)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if !tasks.isEmpty {
                VStack {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.green)

                    Text("\(completedCount) of \(tasks.count) completed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
            }
            
            List {
                ForEach(tasks) { task in
                    HStack {
                        Button(action: {
                            toggleTaskCompletion(task)
                        }) {
                            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(.plain)

                        Text(task.text)
                            .strikethrough(task.completed)
                    }
                }
                .onDelete(perform: deleteTasks)
            }


            // Add new task input
            HStack {
                TextField("New \(selectedScope) Task", text: $newTaskText)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    addTask()
                }
                .disabled(newTaskText.isEmpty)
            }
            .padding()

            Spacer()
        }
        .onAppear {
            fetchTasks()
        }
        .onChange(of: selectedScope) { _ in
            fetchTasks()
        }
        .padding()
    }

    func fetchTasks() {
        guard let uid = uid else { return }

        Firestore.firestore()
            .collection("todo")
            .whereField("userId", isEqualTo: uid)
            .whereField("scope", isEqualTo: selectedScope)
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    self.tasks = docs.map { doc in
                        ToDoTask(
                            id: doc.documentID,
                            text: doc["text"] as? String ?? "",
                            completed: doc["completed"] as? Bool ?? false,
                            scope: doc["scope"] as? String ?? "Daily"
                        )
                    }
                } else {
                    print("⚠️ Failed to fetch tasks: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
    }

    func addTask() {
        guard let uid = uid else { return }
        let taskData: [String: Any] = [
            "userId": uid,
            "text": newTaskText,
            "completed": false,
            "scope": selectedScope,
            "timestamp": Timestamp(date: Date())
        ]
        Firestore.firestore().collection("todo").addDocument(data: taskData) { _ in
            newTaskText = ""
            fetchTasks()
        }
    }

    func toggleTaskCompletion(_ task: ToDoTask) {
        Firestore.firestore().collection("todo").document(task.id).updateData([
            "completed": !task.completed
        ]) { _ in
            fetchTasks()
        }
    }
    
    // MARK: - Task Model
    struct ToDoTask: Identifiable {
        let id: String
        let text: String
        let completed: Bool
        let scope: String
    }

    func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let task = tasks[index]
            Firestore.firestore().collection("todo").document(task.id).delete()
        }
        tasks.remove(atOffsets: offsets)
    }
    
    var completedCount: Int {
        tasks.filter { $0.completed }.count
    }

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }
}


