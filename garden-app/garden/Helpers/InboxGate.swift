import Foundation
import SwiftData

/// The Inbox category is gated behind installation of the Garden Inbox Shortcut.
/// Two paths flip the gate true:
///   1. User taps "Install Garden Inbox Shortcut" in Settings (optimistic).
///   2. AddToGardenInboxIntent runs successfully (definitive).
/// Either path also lazily creates the Inbox category if it doesn't exist.
enum InboxGate {
    static let enabledKey = "garden.inboxEnabled"
    static let inboxIDKey = "garden.inbox.categoryID"

    static var isEnabled: Bool {
        GardenStoreLocator.sharedDefaults.bool(forKey: enabledKey)
    }

    @MainActor
    @discardableResult
    static func enable(in context: ModelContext) -> Category? {
        GardenStoreLocator.sharedDefaults.set(true, forKey: enabledKey)

        let inbox = ensureInboxCategory(in: context)
        if let inbox {
            GardenStoreLocator.sharedDefaults.set(
                inbox.id.uuidString, forKey: inboxIDKey
            )
        }
        // Refreshing the count also reloads widget timelines.
        InboxCountStore.refresh(in: context)

        NotificationCenter.default.post(name: .gardenInboxEnabled, object: nil)
        return inbox
    }

    @MainActor
    private static func ensureInboxCategory(in context: ModelContext) -> Category? {
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        if let existing = all.first(where: { $0.name == "Inbox" }) {
            return existing
        }
        let inbox = Category(name: "Inbox")
        inbox.sortOrder = (all.map(\.sortOrder).min() ?? 1) - 1
        context.insert(inbox)
        do {
            try context.save()
            return inbox
        } catch {
            return nil
        }
    }
}

// Defined here (not in ContentView) so the widget extension target — which
// includes InboxGate but not ContentView — can resolve the symbol when
// AddToGardenInboxIntent posts it.
extension Notification.Name {
    static let gardenInboxEnabled = Notification.Name("garden.inboxEnabled")
}

