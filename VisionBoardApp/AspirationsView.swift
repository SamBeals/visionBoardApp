//
//  AspirationsView.swift
//  VisionBoardApp
//
//  Created by Sam Beals on 8/3/25.
//


import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct AspirationsView: View {
    @State private var aspirations: [Aspiration] = []
    @State private var newAspiration = ""

    private var uid: String? { Auth.auth().currentUser?.uid }

    var body: some View {
        VStack {
            Text("Long-Term Aspirations")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            List {
                ForEach(aspirations) { aspiration in
                    VStack(alignment: .leading) {
                        Text(aspiration.text)
                            .font(.body)
                            .padding(.vertical, 4)
                    }
                }
            }

            HStack {
                TextField("Add a new aspiration", text: $newAspiration)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    addAspiration()
                }
                .disabled(newAspiration.isEmpty)
            }
            .padding()

            Spacer()
        }
        .onAppear {
            fetchAspirations()
        }
        .padding()
    }

    // MARK: - Firestore

    func fetchAspirations() {
        guard let uid = uid else { return }

        Firestore.firestore()
            .collection("aspirations")
            .whereField("userId", isEqualTo: uid)
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    aspirations = docs.map { doc in
                        Aspiration(
                            id: doc.documentID,
                            text: doc["text"] as? String ?? ""
                        )
                    }
                }
            }
    }

    func addAspiration() {
        guard let uid = uid else { return }

        let data: [String: Any] = [
            "userId": uid,
            "text": newAspiration,
            "timestamp": Timestamp(date: Date())
        ]

        Firestore.firestore().collection("aspirations").addDocument(data: data) { _ in
            newAspiration = ""
            fetchAspirations()
        }
    }
}

// MARK: - Model
struct Aspiration: Identifiable {
    let id: String
    let text: String
}
