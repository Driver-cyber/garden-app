import SwiftUI

struct SelectionActionBar: View {
    let count: Int
    let destinationCategories: [Category]
    let onCancel: () -> Void
    let onMove: (UUID) -> Void
    let onManageCategories: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(countLabel)
                .font(.subheadline)
                .foregroundStyle(Color.ink2)

            Spacer()

            Menu {
                if destinationCategories.isEmpty {
                    Text("No other categories yet")
                } else {
                    ForEach(destinationCategories) { cat in
                        Button(cat.name) { onMove(cat.id) }
                    }
                }
                Divider()
                Button {
                    onManageCategories()
                } label: {
                    Label("Manage categories…", systemImage: "pencil")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "tray.and.arrow.up")
                    Text("Move to…")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(canMove ? Color.sageDeep : Color.ink3)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(canMove ? Color.sageTint : Color.line.opacity(0.5))
                )
            }
            .disabled(!canMove)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Color.bg
                .overlay(alignment: .top) {
                    Divider().background(Color.line)
                }
        )
    }

    private var canMove: Bool {
        count > 0 && !destinationCategories.isEmpty
    }

    private var countLabel: String {
        switch count {
        case 0: return "Select notes to move"
        case 1: return "1 selected"
        default: return "\(count) selected"
        }
    }
}
