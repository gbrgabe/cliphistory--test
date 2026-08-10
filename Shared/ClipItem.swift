import Foundation

struct ClipItem: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
    var isPinned: Bool = false

    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isPinned = isPinned
    }
}
