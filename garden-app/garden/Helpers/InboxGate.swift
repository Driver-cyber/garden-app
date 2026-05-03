import Foundation
import SwiftData

/// The Inbox is "enabled" iff a Category named "Inbox" exists in the SwiftData
/// store. Both the main app and the widget extension treat that single signal
/// as truth — no UserDefaults flag, no cross-process sync flakiness.
///
/// Two paths create the Inbox category:
///   1. User taps "Install Garden Inbox Shortcut" in Settings (optimistic).
///   2. AddToGardenInboxIntent runs successfully (definitive).
/// Returning users on a new device also get the Inbox auto-restored when
/// CloudKit syncs the prior install's category back into the store.
enum InboxGate {
    @MainActor
    @discardableResult
    static func enable(in context: ModelContext) -> Category? {
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        if let existing = all.first(where: { $0.name == "Inbox" }) {
            return existing
        }
        let inbox = Category(name: "Inbox")
        inbox.sortOrder = (all.map(\.sortOrder).min() ?? 1) - 1
        context.insert(inbox)
        do {
            try context.save()
            InboxCountStore.refresh(in: context)
            return inbox
        } catch {
            return nil
        }
    }
}
