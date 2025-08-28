import Foundation

struct UploadedImage: Identifiable {
    var id: String
    var url: String
    var type: String
}

struct Habit: Identifiable, Hashable {
    let id: String
    let name: String
    let createdAt: Date
    var photoUrl: String?   // ← new, optional proof photo

}

