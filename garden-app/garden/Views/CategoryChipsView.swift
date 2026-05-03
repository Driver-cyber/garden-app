import SwiftUI

struct CategoryChipsView: View {
    let categories: [Category]
    @Binding var selectedID: UUID?
    let onManage: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            fullStrip
            compactStrip
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }

    private var fullStrip: some View {
        HStack(spacing: 8) {
            Chip(label: "All", isSelected: selectedID == nil) {
                select(nil)
            }
            ForEach(categories) { cat in
                Chip(label: cat.name, isSelected: selectedID == cat.id) {
                    select(cat.id)
                }
            }
            manageButton
            Spacer(minLength: 0)
        }
    }

    private var compactStrip: some View {
        HStack(spacing: 8) {
            Chip(label: "All", isSelected: selectedID == nil) {
                select(nil)
            }
            // Pinned: Inbox always shown when it exists.
            if let inbox = categories.first(where: { $0.name == "Inbox" }) {
                Chip(label: inbox.name, isSelected: selectedID == inbox.id) {
                    select(inbox.id)
                }
            }
            // Currently-selected category if it isn't Inbox.
            if let selectedID,
               let cat = categories.first(where: { $0.id == selectedID }),
               cat.name != "Inbox" {
                Chip(label: cat.name, isSelected: true) {
                    select(nil)
                }
            }
            categoriesMenu
            Spacer(minLength: 0)
        }
    }

    private var categoriesMenu: some View {
        Menu {
            ForEach(categories) { cat in
                Button(cat.name) { select(cat.id) }
            }
            Divider()
            Button {
                onManage()
            } label: {
                Label("Manage categories…", systemImage: "pencil")
            }
        } label: {
            HStack(spacing: 4) {
                Text("Categories")
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .font(.subheadline)
            .foregroundStyle(Color.ink2)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.sageTint)
            .clipShape(Capsule())
        }
    }

    private var manageButton: some View {
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
