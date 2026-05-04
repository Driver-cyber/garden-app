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
            if resolvedCategoryID == nil {
                emptyStateView
            } else {
                composerContent
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

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "tray")
                    .foregroundStyle(Color.sageDeep)
                Text("No categories yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Spacer()
            }
            Text("Install the Garden Inbox Shortcut from Settings, or create your own category to start adding notes.")
                .font(.footnote)
                .foregroundStyle(Color.ink2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                onManageCategories()
            } label: {
                Label("Create category", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.sageDeep)
        }
    }

    @ViewBuilder
    private var composerContent: some View {
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
        // Ensure the SQLite store has the new note before nudging the widget;
        // the widget reads from the file directly and won't see in-memory inserts.
        try? modelContext.save()
        InboxCountStore.refresh(in: modelContext)
    }

    private func defaultTBDID() -> UUID? {
        guard let s = UserDefaults.standard.string(forKey: "garden.tbd.categoryID") else { return nil }
        return UUID(uuidString: s)
    }

    private func defaultInboxID() -> UUID? {
        categories.first(where: { $0.name == "Inbox" })?.id
    }
}
