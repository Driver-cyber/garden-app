import Foundation

enum ExportMarkdown {
    static func generate(notes: [Note], categories: [Category]) -> String {
        let nameOf: (UUID) -> String = { id in
            categories.first(where: { $0.id == id })?.name ?? "Uncategorized"
        }

        let grouped = Dictionary(grouping: notes, by: { $0.categoryID })
        let orderedKeys = grouped.keys.sorted { nameOf($0) < nameOf($1) }

        var md = "# Garden notes\n\n"
        md += "_Exported \(formatted(.now))_\n\n"

        for key in orderedKeys {
            md += "## \(nameOf(key))\n\n"
            for note in (grouped[key] ?? []).sorted(by: { $0.createdAt > $1.createdAt }) {
                md += "- \(formatted(note.createdAt)): \(note.text)\n"
            }
            md += "\n"
        }

        return md
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static func formatted(_ date: Date) -> String {
        formatter.string(from: date)
    }
}
