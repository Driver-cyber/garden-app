import SwiftUI
import SwiftData
import UIKit

struct NotesView: View {
    @Binding var showSettings: Bool

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedCategoryID: UUID?
    @State private var showExport: Bool = false
    @State private var showCategoryManager: Bool = false
    @State private var searchQuery: String = ""
    @State private var inboxEnabled: Bool = InboxGate.isEnabled

    @State private var selectionMode: Bool = false
    @State private var selectedNoteIDs: Set<UUID> = []

    private var visibleCategories: [Category] {
        inboxEnabled ? categories : categories.filter { $0.name != "Inbox" }
    }

    private var visibleSelectedID: UUID? {
        guard let id = selectedCategoryID else { return nil }
        return visibleCategories.contains(where: { $0.id == id }) ? id : nil
    }

    private var moveDestinations: [Category] {
        visibleCategories.filter { $0.id != visibleSelectedID }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    CategoryChipsView(
                        categories: visibleCategories,
                        selectedID: Binding(
                            get: { visibleSelectedID },
                            set: { selectedCategoryID = $0 }
                        ),
                        onManage: { showCategoryManager = true }
                    )
                    .disabled(selectionMode)
                    .opacity(selectionMode ? 0.5 : 1.0)

                    NoteListView(
                        selectedCategoryID: visibleSelectedID,
                        searchQuery: searchQuery,
                        selectionMode: selectionMode,
                        selectedNoteIDs: $selectedNoteIDs
                    )

                    if selectionMode {
                        SelectionActionBar(
                            count: selectedNoteIDs.count,
                            destinationCategories: moveDestinations,
                            onCancel: { exitSelectionMode() },
                            onMove: { categoryID in moveSelected(to: categoryID) },
                            onManageCategories: { showCategoryManager = true }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        NoteComposerView(
                            categories: visibleCategories,
                            filterCategoryID: visibleSelectedID,
                            onManageCategories: { showCategoryManager = true }
                        )
                    }
                }
            }
            .toolbar {
                if selectionMode {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { exitSelectionMode() }
                            .foregroundStyle(Color.sageDeep)
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(Color.sageDeep)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                selectionMode = true
                            }
                        } label: {
                            Text("Select")
                                .foregroundStyle(Color.sageDeep)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showExport = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.sageDeep)
                        }
                    }
                }
            }
            .sheet(isPresented: $showExport) {
                ExportSheet()
            }
            .sheet(isPresented: $showCategoryManager) {
                CategoryManagerSheet()
            }
            .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search notes")
            .onAppear {
                inboxEnabled = InboxGate.isEnabled
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    inboxEnabled = InboxGate.isEnabled
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .gardenInboxEnabled)) { _ in
                inboxEnabled = true
            }
        }
    }

    private func exitSelectionMode() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            selectionMode = false
        }
        selectedNoteIDs = []
    }

    private func moveSelected(to newCategoryID: UUID) {
        guard !selectedNoteIDs.isEmpty else { return }
        let descriptor = FetchDescriptor<Note>()
        guard let allNotes = try? modelContext.fetch(descriptor) else { return }
        let ids = selectedNoteIDs
        for note in allNotes where ids.contains(note.id) {
            note.categoryID = newCategoryID
        }
        try? modelContext.save()
        InboxCountStore.refresh(in: modelContext)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        exitSelectionMode()
    }
}

#Preview {
    NotesView(showSettings: .constant(false))
}
