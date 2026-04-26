import Foundation
import SwiftData

enum NoteStatus: String, Codable {
    case active, archived
}

@Model
final class Note {
    var id: UUID = UUID()
    var categoryID: UUID = UUID()
    var text: String = ""
    var createdAt: Date = Date()
    var status: NoteStatus = NoteStatus.active

    init(categoryID: UUID, text: String) {
        self.categoryID = categoryID
        self.text = text
    }
}
