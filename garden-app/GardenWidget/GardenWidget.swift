import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Snapshot of a single inbox note for the entry

struct InboxNoteSnapshot: Equatable {
    let id: UUID
    let text: String
}

// MARK: - Entry

struct GardenEntry: TimelineEntry {
    let date: Date
    let inboxEnabled: Bool
    let inboxCount: Int
    let currentNote: InboxNoteSnapshot?
    let position: Int  // 0-indexed
}

// MARK: - Provider

struct GardenProvider: TimelineProvider {
    func placeholder(in context: Context) -> GardenEntry {
        GardenEntry(date: Date(), inboxEnabled: false, inboxCount: 0,
                    currentNote: nil, position: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (GardenEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GardenEntry>) -> Void) {
        let entry = currentEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: entry.date)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    /// Read directly from the App Group SwiftData store. Cross-process
    /// UserDefaults sync is unreliable; SQLite reads are not.
    private func currentEntry() -> GardenEntry {
        let schema = Schema([Note.self, Category.self])
        let config = ModelConfiguration(
            schema: schema,
            url: GardenStoreLocator.storeURL,
            cloudKitDatabase: .automatic
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)

            let categories = try context.fetch(FetchDescriptor<Category>())
            guard let inbox = categories.first(where: { $0.name == "Inbox" }) else {
                return GardenEntry(date: Date(), inboxEnabled: false, inboxCount: 0,
                                   currentNote: nil, position: 0)
            }

            let descriptor = FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt)])
            let allNotes = try context.fetch(descriptor)
            let inboxNotes = allNotes.filter { $0.categoryID == inbox.id && $0.status == .active }

            guard !inboxNotes.isEmpty else {
                return GardenEntry(date: Date(), inboxEnabled: true, inboxCount: 0,
                                   currentNote: nil, position: 0)
            }

            let cursorString = GardenStoreLocator.sharedDefaults.string(forKey: InboxWidgetCursor.key)
            let cursorID = cursorString.flatMap(UUID.init(uuidString:))

            let position: Int
            if let cursorID, let idx = inboxNotes.firstIndex(where: { $0.id == cursorID }) {
                position = idx
            } else {
                position = 0
            }

            let current = inboxNotes[position]
            return GardenEntry(
                date: Date(),
                inboxEnabled: true,
                inboxCount: inboxNotes.count,
                currentNote: InboxNoteSnapshot(id: current.id, text: current.text),
                position: position
            )
        } catch {
            return GardenEntry(date: Date(), inboxEnabled: false, inboxCount: 0,
                               currentNote: nil, position: 0)
        }
    }
}

// MARK: - Calm Provider (static, just opens Calm)

struct CalmEntry: TimelineEntry {
    let date: Date
}

struct CalmProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalmEntry { CalmEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (CalmEntry) -> Void) {
        completion(CalmEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CalmEntry>) -> Void) {
        completion(Timeline(entries: [CalmEntry(date: Date())], policy: .never))
    }
}

// MARK: - Inbox checklist (medium)

struct InboxChecklistView: View {
    let entry: GardenEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("garden inbox")
                    .font(.system(.subheadline, design: .serif).italic())
                    .foregroundStyle(Color.ink)
                Spacer()
                if entry.inboxCount > 0 {
                    Text("\(entry.position + 1) of \(entry.inboxCount)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color.ink3)
                }
            }

            if let note = entry.currentNote {
                noteRow(note)
                Spacer(minLength: 0)
                if entry.inboxCount > 1 {
                    HStack {
                        Button(intent: RewindInboxCursorIntent(currentNoteIDString: note.id.uuidString)) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Prev")
                            }
                            .font(.caption)
                            .foregroundStyle(Color.sageDeep)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.sageTint)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(intent: AdvanceInboxCursorIntent(currentNoteIDString: note.id.uuidString)) {
                            HStack(spacing: 4) {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.caption)
                            .foregroundStyle(Color.sageDeep)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.sageTint)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                emptyState
            }
        }
        .padding(14)
        .containerBackground(Color.bg, for: .widget)
    }

    private func noteRow(_ note: InboxNoteSnapshot) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button(intent: ArchiveInboxNoteIntent(noteIDString: note.id.uuidString)) {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundStyle(Color.sageDeep)
            }
            .buttonStyle(.plain)

            Link(destination: URL(string: "garden://inbox")!) {
                Text(note.text)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if entry.inboxEnabled {
            VStack {
                Spacer()
                Text("Inbox is clear")
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundStyle(Color.ink2)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            Link(destination: URL(string: "garden://setup-inbox")!) {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(Color.sageDeep)
                    Text("Tap to set up Inbox")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink2)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Calm small widget

struct CalmSmallView: View {
    var body: some View {
        Link(destination: URL(string: "garden://calm")!) {
            VStack(spacing: 4) {
                Spacer()
                Image(systemName: "leaf")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.sageDeep)
                Text("Calm")
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundStyle(Color.ink)
                Text("one breath")
                    .font(.caption2)
                    .foregroundStyle(Color.ink2)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(Color.bg, for: .widget)
    }
}

// MARK: - Lock Screen accessories

struct LockComposeAccessoryView: View {
    var body: some View {
        Link(destination: URL(string: "garden://compose")!) {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "tray.and.arrow.down")
                    .imageScale(.large)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct LockInboxCountView: View {
    let entry: GardenEntry

    var body: some View {
        Group {
            if entry.inboxEnabled {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Garden")
                        .font(.caption2)
                    Text(headline)
                        .font(.headline)
                    Text("Inbox")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Link(destination: URL(string: "garden://setup-inbox")!) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Garden")
                            .font(.caption2)
                        Text("Set up")
                            .font(.headline)
                        Text("Inbox")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .containerBackground(.clear, for: .widget)
    }

    private var headline: String {
        switch entry.inboxCount {
        case 0: return "all clear"
        case 1: return "1 unsorted"
        default: return "\(entry.inboxCount) unsorted"
        }
    }
}

// MARK: - Widget configurations

struct GardenInboxWidget: Widget {
    let kind: String = "GardenInboxWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GardenProvider()) { entry in
            InboxChecklistView(entry: entry)
        }
        .configurationDisplayName("Garden Inbox")
        .description("Triage your Inbox: tap to archive, tap Next to skim.")
        .supportedFamilies([.systemMedium])
    }
}

struct GardenCalmWidget: Widget {
    let kind: String = "GardenCalmWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalmProvider()) { _ in
            CalmSmallView()
        }
        .configurationDisplayName("Garden Calm")
        .description("Open the wheat field.")
        .supportedFamilies([.systemSmall])
    }
}

struct GardenLockWidget: Widget {
    let kind: String = "GardenLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GardenProvider()) { entry in
            LockWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Garden Lock Screen")
        .description("Quick compose + Inbox count.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

private struct LockWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GardenEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            LockComposeAccessoryView()
        case .accessoryRectangular:
            LockInboxCountView(entry: entry)
        default:
            LockComposeAccessoryView()
        }
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    GardenInboxWidget()
} timeline: {
    GardenEntry(date: .now, inboxEnabled: true, inboxCount: 0, currentNote: nil, position: 0)
    GardenEntry(date: .now, inboxEnabled: false, inboxCount: 0, currentNote: nil, position: 0)
    GardenEntry(
        date: .now, inboxEnabled: true, inboxCount: 5,
        currentNote: InboxNoteSnapshot(id: UUID(), text: "Pick up dry cleaning tomorrow afternoon"),
        position: 1
    )
}
