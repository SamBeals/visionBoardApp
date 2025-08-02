import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth


struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var uploadStatus: String = ""
    @State private var imageType: String = "vision" // or "proof"


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Vision Board Uploader")
                        .font(.title)

                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .cornerRadius(12)
                    } else {
                        Text("No image selected")
                            .foregroundColor(.gray)
                    }

                    PhotosPicker("Select Photo", selection: $selectedItem, matching: .images)
                        .buttonStyle(.borderedProminent)

                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImage = uiImage
                                } else {
                                    print("⚠️ Could not convert selected item to image")
                                }
                            }
                        }
                    Picker("Type", selection: $imageType) {
                        Text("Vision").tag("vision")
                        Text("Proof").tag("proof")
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if selectedImage != nil {
                        Button("Upload to Firebase") {
                            if let image = selectedImage {
                                uploadImageToFirebase(image)
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Text(uploadStatus)
                        .foregroundColor(.blue)

                    Divider().padding()

                    // ✅ Your gallery button
                    NavigationLink("View Your Gallery") {
                        GalleryView()
                    }
                    .padding()
                }
                .padding()
            }
            .onAppear {
                signInAnonymouslyIfNeeded()
            }
        }
    }
    

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

        print("Starting upload to path: \(fileName)")

        let uploadTask = storageRef.putData(imageData, metadata: nil)

        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                print("Upload failed: \(error.localizedDescription)")
                uploadStatus = "Upload failed: \(error.localizedDescription)"
            }
        }

        uploadTask.observe(.success) { snapshot in
            print("Upload succeeded, now retrieving download URL...")
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get URL: \(error.localizedDescription)")
                    uploadStatus = "Failed to get URL: \(error.localizedDescription)"
                } else if let url = url {
                    print("Uploaded! URL: \(url.absoluteString)")
                    uploadStatus = "Uploaded successfully!"
                    Firestore.firestore().collection("images").addDocument(data: [
                        "url": url.absoluteString,
                        "timestamp": Timestamp(date: Date()),
                        "type": imageType,
                        "userId": uid
                    ])
                }
            }
        }
        
    }
    


}
