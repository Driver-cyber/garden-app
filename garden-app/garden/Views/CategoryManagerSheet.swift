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
                Button(noteCount > 0
                       ? "Delete & move \(noteCount) note\(noteCount == 1 ? "" : "s") to Ideas / TBD"
                       : "Delete",
                       role: .destructive) {
                    deletePending()
                }
                Button("Cancel", role: .cancel) {}
            } message: { cat in
                let noteCount = allNotes.filter { $0.categoryID == cat.id }.count
                if noteCount > 0 {
                    Text("Notes will be moved to Ideas / TBD, not deleted.")
                } else {
                    Text("This category has no notes.")
                }
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
        if let tbdID, tbdID != cat.id {
            for note in allNotes where note.categoryID == cat.id {
                note.categoryID = tbdID
            }
        }
        modelContext.delete(cat)
        try? modelContext.save()
        pendingDelete = nil
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
