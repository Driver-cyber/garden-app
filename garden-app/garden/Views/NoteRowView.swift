import SwiftUI
import SwiftData

struct NoteRowView: View {
    @Bindable var note: Note
    let categoryName: String

    @State private var isEditing: Bool = false
    @State private var draft: String = ""
    @FocusState private var isEditFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(categoryName)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.ink3)
                Spacer()
                Text(note.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.ink3)
            }

            if isEditing {
                TextField("Note", text: $draft, axis: .vertical)
                    .lineLimit(1...8)
                    .focused($isEditFocused)
                    .padding(10)
                    .background(Color.bg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { isEditFocused = false }
                                .foregroundStyle(Color.sageDeep)
                        }
                    }
            } else {
                Text(note.text)
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 16) {
                Spacer()
                if isEditing {
                    Button {
                        cancelEdit()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .font(.caption)
                            .foregroundStyle(Color.ink2)
                    }
                    .buttonStyle(.plain)

                    Button {
                        saveEdit()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                            .font(.caption)
                            .foregroundStyle(Color.sageDeep)
                    }
                    .buttonStyle(.plain)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    Button {
                        beginEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.caption)
                            .foregroundStyle(Color.ink2)
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            note.status = .archived
                        }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                            .font(.caption)
                            .foregroundStyle(Color.ink2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.paper)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func beginEdit() {
        draft = note.text
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            isEditing = true
        }
        isEditFocused = true
    }

    private func cancelEdit() {
        isEditFocused = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            isEditing = false
        }
    }

    private func saveEdit() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        note.text = trimmed
        isEditFocused = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            isEditing = false
        }
    }
}
