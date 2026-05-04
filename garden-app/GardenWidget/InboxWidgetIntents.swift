import AppIntents
import Foundation
import SwiftData
import WidgetKit

/// Archive the inbox note with the given ID, then clear the cursor so the
/// next timeline rebuild surfaces the next-oldest active inbox note.
struct ArchiveInboxNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Archive Inbox Note"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Note ID")
    var noteIDString: String

    init() {}
    init(noteIDString: String) {
        self.noteIDString = noteIDString
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: noteIDString) else { return .result() }

        let schema = Schema([Note.self, Category.self])
        let config = ModelConfiguration(
            schema: schema,
            url: GardenStoreLocator.storeURL,
            cloudKitDatabase: .automatic
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let notes = (try? context.fetch(FetchDescriptor<Note>())) ?? []
        if let note = notes.first(where: { $0.id == id }) {
            note.status = .archived
            try? context.save()
        }

        // Clear cursor — provider will fall back to the first inbox note.
        GardenStoreLocator.sharedDefaults.removeObject(forKey: InboxWidgetCursor.key)

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Advance the cursor to the next inbox note (wraps around).
struct AdvanceInboxCursorIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Inbox Note"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Current Note ID")
    var currentNoteIDString: String

    init() {}
    init(currentNoteIDString: String) {
        self.currentNoteIDString = currentNoteIDString
    }

    func perform() async throws -> some IntentResult {
        guard let currentID = UUID(uuidString: currentNoteIDString) else { return .result() }

        let schema = Schema([Note.self, Category.self])
        let config = ModelConfiguration(
            schema: schema,
            url: GardenStoreLocator.storeURL,
            cloudKitDatabase: .automatic
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        guard let inbox = categories.first(where: { $0.name == "Inbox" }) else {
            return .result()
        }

        let descriptor = FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt)])
        let notes = (try? context.fetch(descriptor)) ?? []
        let inboxNotes = notes.filter { $0.categoryID == inbox.id && $0.status == .active }

        guard inboxNotes.count > 1 else {
            // 0 or 1 notes — nowhere to advance.
            return .result()
        }

        let currentIndex = inboxNotes.firstIndex(where: { $0.id == currentID }) ?? -1
        let nextIndex = (currentIndex + 1) % inboxNotes.count
        let nextID = inboxNotes[nextIndex].id

        GardenStoreLocator.sharedDefaults.set(
            nextID.uuidString, forKey: InboxWidgetCursor.key
        )

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

enum InboxWidgetCursor {
    static let key = "garden.widget.inboxCursor"
}
