import SwiftUI
import SwiftData

struct NoteListView: View {
    let selectedCategoryID: UUID?

    @Query(sort: \Note.createdAt, order: .reverse) private var allNotes: [Note]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var archivedExpanded: Bool = false

    private var inSelectedCategory: (Note) -> Bool {
        { note in
            guard let cid = selectedCategoryID else { return true }
            return note.categoryID == cid
        }
    }

    private var active: [Note] {
        allNotes.filter { $0.status == .active && inSelectedCategory($0) }
    }

    private var archived: [Note] {
        allNotes.filter { $0.status == .archived && inSelectedCategory($0) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if active.isEmpty && archived.isEmpty {
                    Text("No notes yet")
                        .font(.custom("InstrumentSerif-Italic", size: 22))
                        .foregroundStyle(Color.ink3)
                        .padding(.top, 40)
                } else {
                    ForEach(active) { note in
                        NoteRowView(note: note, categoryName: categoryName(for: note))
                    }
                    ArchivedNotesSection(
                        archived: archived,
                        categoryName: categoryName(for:),
                        isExpanded: $archivedExpanded
                    )
                }
            }
            .padding(14)
        }
    }

    private func categoryName(for note: Note) -> String {
        categories.first(where: { $0.id == note.categoryID })?.name ?? "—"
    }
}
