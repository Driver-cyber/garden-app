import SwiftUI
import SwiftData

struct NotesView: View {
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var selectedCategoryID: UUID?
    @State private var showExport: Bool = false
    @State private var showCategoryManager: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    NoteComposerView(categories: categories)
                    CategoryChipsView(
                        categories: categories,
                        selectedID: $selectedCategoryID,
                        onManage: { showCategoryManager = true }
                    )
                    NoteListView(selectedCategoryID: selectedCategoryID)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.sageDeep)
                    }
                }
            }
            .sheet(isPresented: $showExport) {
                ExportSheet()
            }
            .sheet(isPresented: $showCategoryManager) {
                CategoryManagerSheet()
            }
        }
    }
}

#Preview {
    NotesView()
}
