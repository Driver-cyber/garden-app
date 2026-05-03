import WidgetKit
import SwiftUI
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
        let defaults = UserDefaults(suiteName: "group.com.drivercyber.garden")
        let count = defaults?.integer(forKey: "garden.inboxCount") ?? 0
        let enabled = defaults?.bool(forKey: "garden.inboxEnabled") ?? false
        return GardenEntry(date: Date(), inboxCount: count, inboxEnabled: enabled)
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

    // Always route Compose to the Shortcut. Reading entry.inboxEnabled here
    // was unreliable — App Group UserDefaults can be stale in the widget
    // process even after WidgetCenter.reloadAllTimelines(). For users who
    // haven't installed the Shortcut yet, the count line below still nudges
    // them to set up; Shortcuts.app's "Shortcut not found" is acceptable
    // recovery feedback for the rare miss.
    private let composeURL = URL(string: "shortcuts://run-shortcut?name=Garden%20Inbox")!

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
                Link(destination: composeURL) {
                    DashboardButtonLabel(
                        icon: "tray.and.arrow.down",
                        title: "Compose",
                        subtitle: "to Inbox"
                    )
                }

                Link(destination: URL(string: "garden://calm")!) {
                    DashboardButtonLabel(
                        icon: "leaf",
                        title: "Calm",
                        subtitle: "one breath"
                    )
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

private struct DashboardButtonLabel: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.sageDeep)
                .padding(.bottom, 2)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ink)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(Color.ink2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
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
        // Always route to the Shortcut for the same reason as DashboardView:
        // App Group defaults sync is too slow to gate a tap action on. The
        // `enabled` flag is kept only as a hint for the icon glyph.
        Link(destination: URL(string: "shortcuts://run-shortcut?name=Garden%20Inbox")!) {
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
