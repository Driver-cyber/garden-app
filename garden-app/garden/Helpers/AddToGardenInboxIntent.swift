import AppIntents
import Foundation
import SwiftData

struct AddToGardenInboxIntent: AppIntent {
    // Title and shortTitle deliberately avoid the substring "Garden Inbox":
    // AppShortcuts auto-registers names that iOS may match against any
    // externally-built shortcuts://run-shortcut?name=... URL, and we want
    // those to route to Shortcuts.app rather than back into Garden.
    static var title: LocalizedStringResource = "Quick Capture"
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
        // shortTitle + phrases avoid "Garden Inbox" verbatim for the same
        // URL-routing reason as the intent title above.
        AppShortcut(
            intent: AddToGardenInboxIntent(),
            phrases: [
                "Quick capture in \(.applicationName)",
                "Capture note in \(.applicationName)",
            ],
            shortTitle: "Quick Capture",
            systemImageName: "tray.and.arrow.down"
        )
    }
}
