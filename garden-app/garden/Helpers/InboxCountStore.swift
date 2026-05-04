import Foundation
import SwiftData
import WidgetKit

/// Used to be a bridge that wrote inbox count into App Group UserDefaults for
/// the widget to read. Now the widget reads SwiftData directly, so this is
/// just a thin wrapper for "the inbox state changed, please reload the
/// timeline." Kept as a named call site for clarity at every place we mutate
/// notes or categories.
enum InboxCountStore {
    @MainActor
    static func refresh(in context: ModelContext) {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Widget-local "I've eyeballed this" tracking. Stored as an array of UUID
/// strings in shared App Group defaults; never written back to SwiftData.
/// Lives here (rather than in the widget extension) so the main-app reconcile
/// can prune stale entries — the widget only ever clears them on archive,
/// which leaks over time when notes are archived/moved/deleted from the app.
enum WidgetDoneNotes {
    static let key = "garden.widget.doneNoteIDs"

    static func isDone(_ id: UUID) -> Bool {
        guard let ids = GardenStoreLocator.sharedDefaults.stringArray(forKey: key) else { return false }
        return ids.contains(id.uuidString)
    }

    static func setDone(_ id: UUID, _ done: Bool) {
        var ids = GardenStoreLocator.sharedDefaults.stringArray(forKey: key) ?? []
        if done {
            if !ids.contains(id.uuidString) { ids.append(id.uuidString) }
        } else {
            ids.removeAll { $0 == id.uuidString }
        }
        GardenStoreLocator.sharedDefaults.set(ids, forKey: key)
    }

    /// Drop any UUID that no longer corresponds to an active Inbox note —
    /// archived, moved, and hard-deleted notes will never show in the widget
    /// again, so their done-marks are dead weight.
    static func prune(activeInboxIDs: Set<UUID>) {
        guard let ids = GardenStoreLocator.sharedDefaults.stringArray(forKey: key),
              !ids.isEmpty else { return }
        let kept = ids.filter { idString in
            guard let id = UUID(uuidString: idString) else { return false }
            return activeInboxIDs.contains(id)
        }
        if kept.count != ids.count {
            GardenStoreLocator.sharedDefaults.set(kept, forKey: key)
        }
    }
}
