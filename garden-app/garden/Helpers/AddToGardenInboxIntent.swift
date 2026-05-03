import AppIntents
import Foundation
import SwiftData

struct AddToGardenInboxIntent: AppIntent {
    static var title: LocalizedStringResource = "Add to Garden Inbox"
    static var description = IntentDescription(
        "Quick-capture a note into Garden's Inbox to sort later."
    )
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Note", requestValueDialog: "What's on your mind?")
    var text: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .result(dialog: "Nothing to add.")
        }

        let schema = Schema([Note.self, Category.self])
        let config = ModelConfiguration(
            schema: schema,
            url: GardenStoreLocator.storeURL,
            cloudKitDatabase: .automatic
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // Ensure the Inbox category exists, then drop the note in.
        guard let inbox = InboxGate.enable(in: context) else {
            return .result(dialog: "Couldn't open the Inbox.")
        }

        context.insert(Note(categoryID: inbox.id, text: trimmed))
        try context.save()

        InboxCountStore.refresh(in: context)

        return .result(dialog: "Saved to Inbox.")
    }
}

struct GardenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddToGardenInboxIntent(),
            phrases: [
                "Add to \(.applicationName) Inbox",
                "Quick note in \(.applicationName)",
                "Capture in \(.applicationName)",
            ],
            shortTitle: "Add to Inbox",
            systemImageName: "tray.and.arrow.down"
        )
    }
}
