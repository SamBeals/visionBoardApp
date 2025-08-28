import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

// 🔒 Fixed UID used everywhere (testing only)
let FIXED_UID = "L1D1xpv24IUwBQqAg1wPD2D3Xq93"

struct MainMenuView: View {
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var uploadStatus: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Welcome to Vision Board")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top)

                NavigationLink(destination: HabitsListView(userId: FIXED_UID)) {
                    MenuButtonView(title: "Habit Tracker", emoji: "📸")
                }

                NavigationLink(destination: ToDoListView(userId: FIXED_UID)) {
                    MenuButtonView(title: "To-Do List", emoji: "✅")
                }

                NavigationLink(destination: AspirationsView()) {
                    MenuButtonView(title: "Long-Term Aspirations", emoji: "🌄")
                }

                NavigationLink(destination: AffirmationsView()) {
                    MenuButtonView(title: "Affirmations", emoji: "💬")
                }

                Button {
                    showingImagePicker = true
                } label: {
                    MenuButtonView(title: "Upload Photo", emoji: "🖼️")
                }

                if let uploadStatus = uploadStatus {
                    Text(uploadStatus)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding()
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedItem,
                matching: .images
            )
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let item = newItem,
                       let data = try? await item.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        uploadImageToFirebase(imageData: data) { success in
                            uploadStatus = success ? "✅ Uploaded!" : "⚠️ Upload failed"
                        }
                    } else {
                        uploadStatus = "⚠️ No image selected"
                    }
                }
            }
        }
    }
}

struct MenuButtonView: View {
    let title: String
    let emoji: String

    var body: some View {
        HStack {
            Text(emoji).font(.largeTitle)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Upload Helper
func uploadImageToFirebase(imageData: Data, completion: @escaping (Bool) -> Void) {
    let userId = FIXED_UID   // 👈 force fixed UID

    let storage = Storage.storage()
    let storageRef = storage.reference()
    let filename = UUID().uuidString + ".jpg"
    let imageRef = storageRef
        .child("users")
        .child(userId)
        .child("images")
        .child(filename)

    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"

    print("🔑 Using fixed UID: \(userId)")
    print("🪣 Storage bucket: \(storageRef.bucket)")
    print("📤 Attempting upload → \(imageRef.fullPath) (\(imageData.count) bytes)")

    imageRef.putData(imageData, metadata: metadata) { _, error in
        if let error = error {
            print("🚨 Upload failed: \(error.localizedDescription)")
            completion(false)
            return
        }

        imageRef.downloadURL { url, error in
            guard let downloadURL = url else {
                print("Failed to get download URL: \(String(describing: error))")
                completion(false)
                return
            }

            Firestore.firestore()
                .collection("users").document(userId)
                .collection("images")
                .addDocument(data: [
                    "url": downloadURL.absoluteString,
                    "timestamp": FieldValue.serverTimestamp()
                ]) { err in
                    if let err = err {
                        print("🚨 Firestore write failed: \(err.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ Image uploaded & linked to user \(userId)")
                        completion(true)
                    }
                }
        }
    }
}
