import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

final class HabitDetailVM: ObservableObject {
    @Published var isDoneToday = false
    @Published var selectedPhoto: PhotosPickerItem? = nil   // 🚨 NEW
    @Published var photoData: Data? = nil                   // 🚨 NEW
    private var listener: ListenerRegistration?

    func start(habitId: String) {
        stop()
        listener = HabitCompletionService.listenIsDoneToday(
            userId: UserSessionHelper.userId,
            habitId: habitId
        ) { [weak self] done in
            Task { @MainActor in
                self?.isDoneToday = done
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func toggle(habitId: String) {
        Task {
            do {
                if isDoneToday {
                    try await HabitCompletionService.unmarkDoneToday(
                        userId: UserSessionHelper.userId,
                        habitId: habitId
                    )
                } else {
                    var photoUrl: String? = nil
                    if let data = photoData {   // 🚨 NEW: upload if photo chosen
                        let storageRef = Storage.storage()
                            .reference()
                            .child("users/\(UserSessionHelper.userId)/habits/\(habitId)/\(UUID().uuidString).jpg")
                        _ = try await storageRef.putDataAsync(data)
                        photoUrl = try await storageRef.downloadURL().absoluteString
                    }

                    try await HabitCompletionService.markDoneToday(
                        userId: UserSessionHelper.userId,
                        habitId: habitId,
                        photoUrl: photoUrl     // 🚨 extend your service to accept this
                    )
                }
            } catch {
                print("toggle completion error:", error)
            }
        }
    }
}

struct HabitDetailView: View {
    let habit: Habit
    @StateObject private var vm = HabitDetailVM()

    var body: some View {
        VStack(spacing: 16) {
            Text(habit.name)
                .font(.largeTitle)
                .padding(.top)

            if let data = vm.photoData, let uiImage = UIImage(data: data) {   // 🚨 NEW
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            } else {
                Text("No photo uploaded yet")
                    .foregroundStyle(.secondary)
            }

            PhotosPicker(                       // 🚨 NEW: picker
                selection: $vm.selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Choose Photo")
            }
            .onChange(of: vm.selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        vm.photoData = data
                    }
                }
            }

            Button {
                vm.toggle(habitId: habit.id)
            } label: {
                HStack {
                    Image(systemName: vm.isDoneToday ? "checkmark.circle.fill" : "circle")
                    Text(vm.isDoneToday ? "Marked Done Today" : "Mark Done Today")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(vm.isDoneToday ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding()
        .navigationTitle(habit.name)
        .onAppear { vm.start(habitId: habit.id) }
        .onDisappear { vm.stop() }
    }
}
