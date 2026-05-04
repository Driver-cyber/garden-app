import SwiftUI
import SwiftData

struct CategoryManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var allNotes: [Note]

    @State private var newName: String = ""
    @State private var pendingDelete: Category?

    private var tbdID: UUID? {
        guard let s = UserDefaults.standard.string(forKey: "garden.tbd.categoryID") else { return nil }
        return UUID(uuidString: s)
    }

    /// Resolve where notes should land when a category is deleted.
    /// Preference: legacy TBD (if user has one) → Inbox → any other category.
    /// Returns nil only when the deleted category is the user's last one.
    private func reassignmentTarget(excluding catID: UUID) -> Category? {
        if let tbdID, let tbd = categories.first(where: { $0.id == tbdID && $0.id != catID }) {
            return tbd
        }
        if let inbox = categories.first(where: { $0.name == "Inbox" && $0.id != catID }) {
            return inbox
        }
        return categories.first(where: { $0.id != catID })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(categories) { cat in
                        CategoryRow(category: cat, isProtected: cat.id == tbdID)
                    }
                    .onMove(perform: move)
                    .onDelete(perform: askDelete)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.bg)

                HStack(spacing: 10) {
                    TextField("New category", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit(addCategory)
                    Button("Add", action: addCategory)
                        .buttonStyle(.borderedProminent)
                        .tint(Color.sageDeep)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .background(Color.bg)
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete \(pendingDelete?.name ?? "")?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { cat in
                let noteCount = allNotes.filter { $0.categoryID == cat.id }.count
                let target = reassignmentTarget(excluding: cat.id)
                Button(deleteButtonLabel(noteCount: noteCount, target: target),
                       role: .destructive) {
                    deletePending()
                }
                Button("Cancel", role: .cancel) {}
            } message: { cat in
                let noteCount = allNotes.filter { $0.categoryID == cat.id }.count
                let target = reassignmentTarget(excluding: cat.id)
                Text(deleteMessage(noteCount: noteCount, target: target))
            }
        }
    }

    private func addCategory() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let nextSort = (categories.map(\.sortOrder).max() ?? -1) + 1
        let cat = Category(name: name)
        cat.sortOrder = nextSort
        modelContext.insert(cat)
        try? modelContext.save()
        newName = ""
    }

    private func move(from: IndexSet, to: Int) {
        var reordered = categories
        reordered.move(fromOffsets: from, toOffset: to)
        for (index, cat) in reordered.enumerated() {
            cat.sortOrder = index
        }
        try? modelContext.save()
    }

    private func askDelete(_ offsets: IndexSet) {
        guard let i = offsets.first else { return }
        let cat = categories[i]
        guard cat.id != tbdID else { return }
        pendingDelete = cat
    }

    private func deletePending() {
        guard let cat = pendingDelete else { return }
        if let target = reassignmentTarget(excluding: cat.id) {
            for note in allNotes where note.categoryID == cat.id {
                note.categoryID = target.id
            }
        }
        modelContext.delete(cat)
        try? modelContext.save()
        pendingDelete = nil
    }

    private func deleteButtonLabel(noteCount: Int, target: Category?) -> String {
        guard noteCount > 0 else { return "Delete" }
        let noun = "note\(noteCount == 1 ? "" : "s")"
        if let target {
            return "Delete & move \(noteCount) \(noun) to \(target.name)"
        }
        return "Delete & uncategorize \(noteCount) \(noun)"
    }

    private func deleteMessage(noteCount: Int, target: Category?) -> String {
        guard noteCount > 0 else { return "This category has no notes." }
        if let target {
            return "Notes will be moved to \(target.name), not deleted."
        }
        return "Notes will lose their category but the text remains. Recover them from the All filter via Select → Move to."
    }
}

private struct CategoryRow: View {
    @Bindable var category: Category
    let isProtected: Bool

    var body: some View {
        HStack {
            TextField("Name", text: $category.name)
                .disabled(isProtected)
                .foregroundStyle(isProtected ? Color.ink3 : Color.ink)
            if isProtected {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Color.ink3)
            }
        }
    }
}
