import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth


struct GalleryView: View {
    @State private var images: [UploadedImage] = []

    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(images) { image in
                    VStack {
                        AsyncImage(url: URL(string: image.url)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .clipped()
                                    .cornerRadius(10)
                            case .failure(_):
                                Color.red.frame(height: 150)
                            case .empty:
                                ProgressView().frame(height: 150)
                            @unknown default:
                                EmptyView()
                            }
                        }

                        Text(image.type.capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Your Gallery")
        .onAppear {
            fetchImages()
        }
    }

    func fetchImages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("images")
            .whereField("userId", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching images: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.images = documents.compactMap { doc in
                    let data = doc.data()
                    guard let url = data["url"] as? String,
                          let type = data["type"] as? String else {
                        return nil
                    }
                    return UploadedImage(id: doc.documentID, url: url, type: type)
                }
            }
    }
}

