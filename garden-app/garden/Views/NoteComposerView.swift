import SwiftUI
import SwiftData

struct NoteComposerView: View {
    let categories: [Category]
    var filterCategoryID: UUID? = nil
    var onManageCategories: () -> Void = {}
    @Environment(\.modelContext) private var modelContext
    @State private var draft: String = ""
    @State private var draftCategoryID: UUID?
    @FocusState private var isComposerFocused: Bool

    private var resolvedCategoryID: UUID? {
        let candidates: [UUID?] = [
            draftCategoryID,
            filterCategoryID,
            defaultInboxID(),
            defaultTBDID(),
            categories.first?.id,
        ]
        return candidates.compactMap { $0 }.first { id in
            categories.contains(where: { $0.id == id })
        }
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
                    Divider()
                    Button {
                        onManageCategories()
                    } label: {
                        Label("Manage categories…", systemImage: "pencil")
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
                .lineLimit(isComposerFocused ? 4...8 : 1...4)
                .focused($isComposerFocused)
                .padding(12)
                .frame(minHeight: isComposerFocused ? 96 : 40, alignment: .top)
                .background(Color.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .animation(.easeInOut(duration: 0.18), value: isComposerFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("Done") { isComposerFocused = false }
                            .foregroundStyle(Color.sageDeep)
                        Spacer()
                        Button("Add") { addNote() }
                            .disabled(!canAdd)
                            .foregroundStyle(canAdd ? Color.sageDeep : Color.ink3)
                            .bold()
                    }
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Color.bg
                .overlay(alignment: .top) {
                    Divider().background(Color.line)
                }
        )
        .onChange(of: filterCategoryID) { _, new in
            draftCategoryID = new
        }
        .onReceive(NotificationCenter.default.publisher(for: .gardenFocusComposer)) { _ in
            isComposerFocused = true
        }
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
        InboxCountStore.refresh(in: modelContext)
    }

    private func defaultTBDID() -> UUID? {
        guard let s = UserDefaults.standard.string(forKey: "garden.tbd.categoryID") else { return nil }
        return UUID(uuidString: s)
    }

    private func defaultInboxID() -> UUID? {
        guard let s = GardenStoreLocator.sharedDefaults.string(forKey: "garden.inbox.categoryID") else { return nil }
        return UUID(uuidString: s)
    }
}
