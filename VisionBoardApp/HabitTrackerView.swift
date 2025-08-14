import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct HabitTrackerView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var uploadStatus: String = ""
    @State private var imageType: String = "proof" // default: proof of habit

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Habit Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Show selected image or placeholder
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(12)
                } else {
                    Text("Select a photo as proof of your habit.")
                        .foregroundColor(.gray)
                        .padding()
                }

                // Image picker
                PhotosPicker("Select Photo", selection: $selectedItem, matching: .images)
                    .buttonStyle(.borderedProminent)

                // Vision vs Proof toggle
                Picker("Type", selection: $imageType) {
                    Text("Proof").tag("proof")
                    Text("Vision").tag("vision")
                }
                .pickerStyle(.segmented)
                .padding()

                // Upload button
                if selectedImage != nil {
                    Button("Upload") {
                        if let image = selectedImage {
                            uploadImageToFirebase(image)
                        }
                    }
                    .buttonStyle(.bordered)
                }

                // Upload status
                Text(uploadStatus)
                    .foregroundColor(.blue)

                // View gallery
                NavigationLink("View Gallery") {
                    GalleryView()
                }
                .padding(.top, 10)
            }
            .padding()
        }
        // When user selects an image, load it into selectedImage
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                } else {
                    print("⚠️ Failed to load image from picker")
                }
            }
        }
        .onAppear {
            signInAnonymouslyIfNeeded()
        }
    }

    // MARK: - Firebase Upload
    func uploadImageToFirebase(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            uploadStatus = "Failed to convert image."
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            uploadStatus = "User not signed in"
            return
        }

        let fileName = "user_uploads/\(uid)/\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child(fileName)

        uploadStatus = "Uploading..."

        let uploadTask = storageRef.putData(imageData, metadata: nil)

        uploadTask.observe(.success) { _ in
            storageRef.downloadURL { url, error in
                if let url = url {
                    uploadStatus = "Uploaded!"

                    Firestore.firestore().collection("images").addDocument(data: [
                        "url": url.absoluteString,
                        "timestamp": Timestamp(date: Date()),
                        "type": imageType,
                        "userId": uid
                    ]) { error in
                        if let error = error {
                            print("❌ Firestore save failed: \(error.localizedDescription)")
                        } else {
                            print("📦 Firestore record saved.")
                        }
                    }
                }
            }
        }

        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                uploadStatus = "Upload failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Anonymous Sign-in
    func signInAnonymouslyIfNeeded() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("❌ Anonymous sign-in failed: \(error.localizedDescription)")
                } else {
                    print("✅ Signed in anonymously")
                }
            }
        }
    }
}
