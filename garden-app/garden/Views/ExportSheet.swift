import SwiftUI
import SwiftData
import UIKit

struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Note.createdAt, order: .reverse) private var allNotes: [Note]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var step: Step = .preview
    @State private var selectedCategoryID: UUID?
    @State private var notesToArchive: Set<UUID> = []
    @State private var copyConfirm: Bool = false

    enum Step { case preview, archive }

    private var exportNotes: [Note] {
        allNotes.filter { note in
            note.status == .active &&
                (selectedCategoryID == nil || note.categoryID == selectedCategoryID)
        }
    }

    private var markdown: String {
        ExportMarkdown.generate(notes: exportNotes, categories: categories)
    }

    private var selectedCategoryName: String {
        guard let id = selectedCategoryID else { return "All notes" }
        return categories.first(where: { $0.id == id })?.name ?? "All notes"
    }

    var body: some View {
        NavigationStack {
            Group {
                if step == .preview {
                    previewView
                } else {
                    archiveView
                }
            }
            .background(Color.bg.ignoresSafeArea())
            .navigationTitle(step == .preview ? "Export" : "Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == .archive {
                        Button("Back") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                step = .preview
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: Preview

    private var previewView: some View {
        VStack(spacing: 12) {
            HStack {
                Menu {
                    Button("All") { selectedCategoryID = nil }
                    ForEach(categories) { cat in
                        Button(cat.name) { selectedCategoryID = cat.id }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                        Text(selectedCategoryName)
                        Image(systemName: "chevron.down").font(.caption2)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.ink2)
                }
                Spacer()
                Text("\(exportNotes.count) note\(exportNotes.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Color.ink3)
            }
            .padding(.horizontal)

            ScrollView {
                Text(markdown)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            HStack(spacing: 10) {
                Button(action: copy) {
                    Label(copyConfirm ? "Copied" : "Copy",
                          systemImage: copyConfirm ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Color.sageDeep)

                ShareLink(item: markdown,
                          subject: Text("Garden notes"),
                          message: Text("")) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.sageDeep)
            }
            .padding(.horizontal)

            Button {
                notesToArchive = Set(exportNotes.map(\.id))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                    step = .archive
                }
            } label: {
                HStack {
                    Text("Choose what to archive")
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
                .foregroundStyle(Color.ink2)
            }
            .disabled(exportNotes.isEmpty)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
    }

    private func copy() {
        UIPasteboard.general.string = markdown
        copyConfirm = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copyConfirm = false
        }
    }

    // MARK: Archive

    private var groupedSections: [(category: Category?, notes: [Note])] {
        let grouped = Dictionary(grouping: exportNotes, by: \.categoryID)
        let pairs: [(Category?, [Note])] = grouped.map { cid, notes in
            let cat = categories.first(where: { $0.id == cid })
            return (cat, notes)
        }
        return pairs.sorted { lhs, rhs in
            (lhs.0?.sortOrder ?? .max) < (rhs.0?.sortOrder ?? .max)
        }
    }

    private var archiveView: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8, pinnedViews: []) {
                    ForEach(groupedSections, id: \.category?.id) { section in
                        Text(section.category?.name ?? "—")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color.ink3)
                            .padding(.top, 6)
                            .padding(.horizontal, 4)

                        ForEach(section.notes) { note in
                            ArchiveCheckRow(
                                note: note,
                                isSelected: notesToArchive.contains(note.id)
                            ) { toggle(note.id) }
                        }
                    }
                }
                .padding()
            }

            HStack(spacing: 10) {
                Button("Keep all active") { dismiss() }
                    .buttonStyle(.bordered)
                    .tint(Color.ink2)
                    .frame(maxWidth: .infinity)

                Button {
                    archiveSelected()
                    dismiss()
                } label: {
                    Text("Archive \(notesToArchive.count)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.sageDeep)
                .disabled(notesToArchive.isEmpty)
            }
            .padding()
        }
    }

    private func toggle(_ id: UUID) {
        if notesToArchive.contains(id) {
            notesToArchive.remove(id)
        } else {
            notesToArchive.insert(id)
        }
    }

    private func archiveSelected() {
        for note in allNotes where notesToArchive.contains(note.id) {
            note.status = .archived
        }
        try? modelContext.save()
    }
}

private struct ArchiveCheckRow: View {
    let note: Note
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? Color.sageDeep : Color.ink3)
                    .font(.title3)
                Text(note.text)
                    .lineLimit(3)
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
