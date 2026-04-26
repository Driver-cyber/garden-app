import SwiftUI

struct CalmView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.sky, Color.sky.opacity(0.45), Color.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            WheatFieldView()
                .frame(height: 260)
                .ignoresSafeArea(edges: .bottom)

            VStack {
                Spacer()
                OneThingCard()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 300)
            }
        }
    }
}

#Preview {
    CalmView()
}
