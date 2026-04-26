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
            VStack(spacing: 18) {
                Text("Breathe.")
                    .font(.custom("InstrumentSerif-Italic", size: 44))
                    .foregroundStyle(Color.ink)

                Text("One thing. One breath. One check.")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink2)

                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isCheckedToday ? Color.sageDeep : Color.bg)
                        .frame(width: 96, height: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.line, lineWidth: 1.5)
                        )

                    if isCheckedToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(Color.paper)
                    }

                    ConfettiView(trigger: confettiTrigger)
                }
                .padding(.vertical, 4)

                Text("Tap when you've done the one thing.")
                    .font(.custom("InstrumentSerif-Italic", size: 17))
                    .foregroundStyle(Color.ink3)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .background(Color.paper)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
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
