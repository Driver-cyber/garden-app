import SwiftUI
import SwiftData

struct ArchivedNotesSection: View {
    let archived: [Note]
    let categoryName: (Note) -> String
    @Binding var isExpanded: Bool

    var body: some View {
        if archived.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                        Text("Archived (\(archived.count))")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundStyle(Color.ink2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    LazyVStack(spacing: 8) {
                        ForEach(archived) { note in
                            ArchivedNoteRow(note: note, categoryName: categoryName(note))
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}

private struct ArchivedNoteRow: View {
    @Bindable var note: Note
    let categoryName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(categoryName)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.ink3)
                Spacer()
                Text(note.createdAt, format: .dateTime.month(.abbreviated).day())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.ink3)
            }
            Text(note.text)
                .foregroundStyle(Color.ink2)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        note.status = .active
                    }
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                        .font(.caption)
                        .foregroundStyle(Color.sageDeep)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.paper.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
