import SwiftUI
import SwiftData

struct NoteRowView: View {
    @Bindable var note: Note
    let categoryName: String

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

            Text(note.text)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer()
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
        .padding(16)
        .background(Color.paper)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
