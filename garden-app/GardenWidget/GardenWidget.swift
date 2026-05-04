import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Entry & Provider

struct GardenEntry: TimelineEntry {
    let date: Date
    let inboxCount: Int
    let inboxEnabled: Bool
}

struct GardenProvider: TimelineProvider {
    func placeholder(in context: Context) -> GardenEntry {
        GardenEntry(date: Date(), inboxCount: 0, inboxEnabled: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (GardenEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GardenEntry>) -> Void) {
        let entry = currentEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: entry.date)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> GardenEntry {
        let snap = readSnapshot()
        return GardenEntry(date: Date(), inboxCount: snap.count, inboxEnabled: snap.enabled)
    }

    /// Read directly from the App Group SwiftData store instead of UserDefaults.
    /// Cross-process UserDefaults sync between the main app and the widget process
    /// is famously laggy — even after WidgetCenter.reloadAllTimelines(). The local
    /// SQLite store is the source of truth and SQLite handles concurrent reads
    /// from a separate process cleanly.
    private func readSnapshot() -> (count: Int, enabled: Bool) {
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
                return (0, false)
            }
            let notes = try context.fetch(FetchDescriptor<Note>())
            let count = notes.filter { $0.categoryID == inbox.id && $0.status == .active }.count
            return (count, true)
        } catch {
            return (0, false)
        }
    }
}

// MARK: - Bundle Entry View

struct GardenWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GardenEntry

    var body: some View {
        switch family {
        case .systemMedium:
            DashboardView(entry: entry)
        case .accessoryCircular:
            QuickComposeAccessoryView(enabled: entry.inboxEnabled)
        case .accessoryRectangular:
            InboxCountAccessoryView(entry: entry)
        default:
            DashboardView(entry: entry)
        }
    }
}

// MARK: - Dashboard (Home Screen Medium)

private struct DashboardView: View {
    let entry: GardenEntry

    // Open Garden directly to the composer instead of routing to the
    // Shortcut. Widget Link → shortcuts://run-shortcut?name=… proved
    // unreliable in iOS — UIApplication.openURL was choosing the host
    // app over Shortcuts.app despite no claim to that scheme. The
    // silent-capture path is still available via the Action Button and
    // Siri ("Quick capture in Garden"), both of which invoke the user's
    // Garden Inbox Shortcut without going through a widget Link.
    private let composeURL = URL(string: "garden://compose")!

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("garden")
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundStyle(Color.ink)
                Spacer()
                Link(destination: URL(string: "garden://notes")!) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink2)
                }
            }

            HStack(spacing: 8) {
                VStack(spacing: 8) {
                    Link(destination: composeURL) {
                        CompactButtonLabel(
                            icon: "tray.and.arrow.down",
                            title: "Compose"
                        )
                    }
                    Link(destination: URL(string: "garden://inbox")!) {
                        CompactButtonLabel(
                            icon: "tray.full",
                            title: "Inbox"
                        )
                    }
                }

                Link(destination: URL(string: "garden://calm")!) {
                    BigCalmButton()
                }
            }

            if entry.inboxEnabled {
                HStack(spacing: 6) {
                    Image(systemName: "tray")
                        .font(.caption2)
                    Text(inboxLine)
                        .font(.caption)
                    Spacer()
                }
                .foregroundStyle(Color.ink3)
            } else {
                Link(destination: URL(string: "garden://setup-inbox")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("Tap to set up Inbox")
                            .font(.caption)
                        Spacer()
                    }
                    .foregroundStyle(Color.ink3)
                }
            }
        }
        .padding(12)
        .containerBackground(Color.bg, for: .widget)
    }

    private var inboxLine: String {
        switch entry.inboxCount {
        case 0: return "Inbox is clear"
        case 1: return "1 unsorted in Inbox"
        default: return "\(entry.inboxCount) unsorted in Inbox"
        }
    }
}

private struct CompactButtonLabel: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.sageDeep)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ink)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.line, lineWidth: 0.5)
        )
    }
}

private struct BigCalmButton: View {
    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            Image(systemName: "leaf")
                .font(.title)
                .foregroundStyle(Color.sageDeep)
            Text("Calm")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ink)
            Text("one breath")
                .font(.caption2)
                .foregroundStyle(Color.ink2)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 8)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.line, lineWidth: 0.5)
        )
    }
}

// MARK: - Lock Screen Circular (Quick Compose)

private struct QuickComposeAccessoryView: View {
    let enabled: Bool

    var body: some View {
        // Same routing as the dashboard Compose: open Garden's composer.
        // Lock-screen taps require unlock anyway, so the trade-off is
        // smaller here. Silent capture stays on the Action Button.
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

// MARK: - Lock Screen Rectangular (Inbox Count / Setup)

private struct InboxCountAccessoryView: View {
    let entry: GardenEntry

    var body: some View {
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
            .containerBackground(.clear, for: .widget)
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
            .containerBackground(.clear, for: .widget)
        }
    }

    private var headline: String {
        switch entry.inboxCount {
        case 0: return "all clear"
        case 1: return "1 unsorted"
        default: return "\(entry.inboxCount) unsorted"
        }
    }
}

// MARK: - Widget

struct GardenWidget: Widget {
    let kind: String = "GardenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GardenProvider()) { entry in
            GardenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Garden")
        .description("Compose to Inbox, jump to Calm, see what's unsorted.")
        .supportedFamilies([
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}

#Preview(as: .systemMedium) {
    GardenWidget()
} timeline: {
    GardenEntry(date: .now, inboxCount: 0, inboxEnabled: false)
    GardenEntry(date: .now, inboxCount: 0, inboxEnabled: true)
    GardenEntry(date: .now, inboxCount: 4, inboxEnabled: true)
}
