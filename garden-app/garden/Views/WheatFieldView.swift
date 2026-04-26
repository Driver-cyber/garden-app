import SwiftUI

struct WheatFieldView: View {
    private static let bladeCount = 80
    private static let waves = 1.6
    private static let periodSeconds: Double = 3.3
    private static let maxAngleDegrees: Double = 6

    @State private var blades: [Blade] = WheatFieldView.makeBlades()

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                drawField(ctx: ctx, size: size, t: t)
            }
        }
    }

    private func drawField(ctx: GraphicsContext, size: CGSize, t: TimeInterval) {
        let baseY = size.height
        let angleScale = Self.maxAngleDegrees * .pi / 180
        let omega = 2 * Double.pi / Self.periodSeconds

        for blade in blades {
            let width = 2.0 + blade.widthRatio * 2.0
            let height = size.height * blade.heightRatio
            let x = size.width * blade.x
            let angle = sin(t * omega + blade.phase) * angleScale

            let transform = CGAffineTransform.identity
                .translatedBy(x: x, y: baseY)
                .rotated(by: CGFloat(angle))
                .translatedBy(x: -width / 2, y: -height)

            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let path = Path(roundedRect: rect, cornerRadius: width / 2).applying(transform)
            ctx.fill(path, with: .color(.wheat))
        }
    }

    private static func makeBlades() -> [Blade] {
        (0..<bladeCount).map { i in
            let t = Double(i) / Double(bladeCount)
            return Blade(
                x: t + Double.random(in: -0.005...0.005),
                widthRatio: Double.random(in: 0.4...1.0),
                heightRatio: Double.random(in: 0.55...1.0),
                phase: -t * 2 * .pi * waves + Double.random(in: -0.4...0.4)
            )
        }
    }

    private struct Blade {
        let x: Double
        let widthRatio: Double
        let heightRatio: Double
        let phase: Double
    }
}

#Preview {
    WheatFieldView()
        .frame(height: 260)
        .background(Color.bg)
}
