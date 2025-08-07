//
//  AffirmationsView.swift
//  VisionBoardApp
//
//  Created by Sam Beals on 8/3/25.
//


import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct AffirmationsView: View {
    @State private var affirmations: [Affirmation] = []
    @State private var newAffirmation = ""

    private var uid: String? { Auth.auth().currentUser?.uid }

    var body: some View {
        VStack {
            Text("Affirmations")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            List {
                ForEach(affirmations) { affirmation in
                    VStack(alignment: .leading) {
                        Text("💬 \(affirmation.text)")
                            .font(.body)
                            .padding(.vertical, 4)
                    }
                }
            }

            HStack {
                TextField("Write a new affirmation", text: $newAffirmation)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    addAffirmation()
                }
                .disabled(newAffirmation.isEmpty)
            }
            .padding()

            Spacer()
        }
        .onAppear {
            fetchAffirmations()
        }
        .padding()
    }

    // MARK: Firestore

    func fetchAffirmations() {
        guard let uid = uid else { return }

        Firestore.firestore()
            .collection("affirmations")
            .whereField("userId", isEqualTo: uid)
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    affirmations = docs.map { doc in
                        Affirmation(
                            id: doc.documentID,
                            text: doc["text"] as? String ?? ""
                        )
                    }
                }
            }
    }

    func addAffirmation() {
        guard let uid = uid else { return }

        let data: [String: Any] = [
            "userId": uid,
            "text": newAffirmation,
            "timestamp": Timestamp(date: Date())
        ]

        Firestore.firestore().collection("affirmations").addDocument(data: data) { _ in
            newAffirmation = ""
            fetchAffirmations()
        }
    }
}

// MARK: - Model
struct Affirmation: Identifiable {
    let id: String
    let text: String
}
