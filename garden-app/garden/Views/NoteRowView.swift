import SwiftUI
import SwiftData

struct NoteRowView: View {
    @Bindable var note: Note
    let categoryName: String
    var selectionMode: Bool = false
    var isSelected: Bool = false
    var onSelectTap: () -> Void = {}

    @State private var isEditing: Bool = false
    @State private var draft: String = ""
    @FocusState private var isEditFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if selectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.sageDeep : Color.ink3)
                    .padding(.top, 18)
                    .transition(.opacity)
            }

            cardBody
                .opacity(selectionMode && !isSelected ? 0.6 : 1.0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if selectionMode { onSelectTap() }
        }
        .onChange(of: selectionMode) { _, newValue in
            if newValue && isEditing {
                cancelEdit()
            }
        }
    }

    private var cardBody: some View {
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

            if !selectionMode {
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
        }
        .padding(16)
        .background(Color.paper)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.sageDeep : Color.line,
                        lineWidth: isSelected ? 1.5 : 1)
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
