import SwiftUI
import SwiftData

struct NoteComposerView: View {
    let categories: [Category]
    @Environment(\.modelContext) private var modelContext
    @State private var draft: String = ""
    @State private var draftCategoryID: UUID?
    @FocusState private var isComposerFocused: Bool

    private var resolvedCategoryID: UUID? {
        draftCategoryID ?? defaultTBDID() ?? categories.first?.id
    }

    private var resolvedCategoryName: String {
        guard let id = resolvedCategoryID,
              let cat = categories.first(where: { $0.id == id }) else { return "Category" }
        return cat.name
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Menu {
                    ForEach(categories) { cat in
                        Button(cat.name) { draftCategoryID = cat.id }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                        Text(resolvedCategoryName)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.ink2)
                }
                Spacer()
            }

            TextField("New note…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .focused($isComposerFocused)
                .padding(12)
                .background(Color.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { isComposerFocused = false }
                            .foregroundStyle(Color.sageDeep)
                    }
                }

            HStack {
                Spacer()
                Button("Add") { addNote() }
                    .disabled(!canAdd)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.sageDeep)
            }
        }
        .padding(14)
    }

    private var canAdd: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && resolvedCategoryID != nil
    }

    private func addNote() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let cid = resolvedCategoryID else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            modelContext.insert(Note(categoryID: cid, text: trimmed))
            draft = ""
        }
        isComposerFocused = false
    }

    private func defaultTBDID() -> UUID? {
        guard let s = UserDefaults.standard.string(forKey: "garden.tbd.categoryID") else { return nil }
        return UUID(uuidString: s)
    }
}
