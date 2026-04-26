import SwiftUI

struct CategoryChipsView: View {
    let categories: [Category]
    @Binding var selectedID: UUID?
    let onManage: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(label: "All", isSelected: selectedID == nil) {
                    select(nil)
                }
                ForEach(categories) { cat in
                    Chip(label: cat.name, isSelected: selectedID == cat.id) {
                        select(cat.id)
                    }
                }
                Button(action: onManage) {
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(
                            Capsule().stroke(Color.line, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
        }
    }

    private func select(_ id: UUID?) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            selectedID = id
        }
    }
}

private struct Chip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(isSelected ? Color.bg : Color.ink2)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.sageDeep : Color.sageTint)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
