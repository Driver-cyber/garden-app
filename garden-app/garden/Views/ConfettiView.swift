import SwiftUI

struct ConfettiView: View {
    let trigger: Int
    @State private var pieces: [Piece] = []

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                ConfettiPiece(piece: piece)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in spawn() }
    }

    private func spawn() {
        let new = (0..<26).map { _ in Piece.random() }
        pieces.append(contentsOf: new)
        let ids = Set(new.map(\.id))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            pieces.removeAll { ids.contains($0.id) }
        }
    }

    struct Piece: Identifiable {
        let id = UUID()
        let color: Color
        let size: CGSize
        let targetOffset: CGSize
        let targetRotation: Double

        static func random() -> Piece {
            let palette: [Color] = [.sageDeep, .sageSoft, .blush, .wheat, .sky]
            let angle = Double.random(in: 0..<2 * .pi)
            let distance = Double.random(in: 70...160)
            return Piece(
                color: palette.randomElement()!,
                size: CGSize(width: Double.random(in: 4...8), height: Double.random(in: 12...18)),
                targetOffset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance - 50
                ),
                targetRotation: Double.random(in: -360...360)
            )
        }
    }
}

private struct ConfettiPiece: View {
    let piece: ConfettiView.Piece
    @State private var animated: Bool = false

    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: piece.size.width, height: piece.size.height)
            .rotationEffect(.degrees(animated ? piece.targetRotation : 0))
            .offset(animated ? piece.targetOffset : .zero)
            .opacity(animated ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1.6)) {
                    animated = true
                }
            }
    }
}
