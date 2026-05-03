import Foundation
import SwiftData
import WidgetKit

enum InboxCountStore {
    static let suiteName = "group.com.drivercyber.garden"
    static let countKey = "garden.inboxCount"

    static func read() -> Int {
        UserDefaults(suiteName: suiteName)?.integer(forKey: countKey) ?? 0
    }

    @MainActor
    static func refresh(in context: ModelContext) {
        guard let inboxIDStr = GardenStoreLocator.sharedDefaults.string(forKey: "garden.inbox.categoryID"),
              let inboxID = UUID(uuidString: inboxIDStr) else {
            write(0)
            return
        }

        let descriptor = FetchDescriptor<Note>()
        let allNotes = (try? context.fetch(descriptor)) ?? []
        let count = allNotes.filter { $0.categoryID == inboxID && $0.status == .active }.count
        write(count)
    }

    private static func write(_ count: Int) {
        UserDefaults(suiteName: suiteName)?.set(count, forKey: countKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
