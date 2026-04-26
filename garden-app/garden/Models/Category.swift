import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    init(name: String) {
        self.name = name
    }
}
