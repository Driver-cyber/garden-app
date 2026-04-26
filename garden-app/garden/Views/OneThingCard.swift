import SwiftUI
import UIKit

struct OneThingCard: View {
    @AppStorage("garden.oneThingCheckedAt") private var checkedAt: Double = 0
    @State private var confettiTrigger: Int = 0

    private var isCheckedToday: Bool {
        guard checkedAt > 0 else { return false }
        return Calendar.current.isDateInToday(Date(timeIntervalSince1970: checkedAt))
    }

    var body: some View {
        Button(action: tap) {
            HStack(spacing: 14) {
                ZStack {
                    Image(systemName: isCheckedToday ? "checkmark.square.fill" : "square")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(isCheckedToday ? Color.sageDeep : Color.ink3)
                    ConfettiView(trigger: confettiTrigger)
                }
                Text("I did the one thing today")
                    .font(.custom("InstrumentSerif-Italic", size: 22))
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color.paper)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func tap() {
        if isCheckedToday {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                checkedAt = 0
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                checkedAt = Date.now.timeIntervalSince1970
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            confettiTrigger += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

#Preview {
    OneThingCard()
        .padding()
        .background(Color.bg)
}
