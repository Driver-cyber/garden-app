import SwiftUI
import UIKit

struct WheatFieldView: View {
    private static let bladeCount = 80
    private static let waves = 1.6
    private static let periodSeconds: Double = 3.3
    private static let maxAngleDegrees: Double = 6
    private static let shadeOffsets: [Double] = [-0.20, -0.10, 0, 0.08, 0.16]

    @State private var blades: [Blade] = WheatFieldView.makeBlades()

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                drawField(ctx: ctx, size: size, t: t, palette: wheatShades())
            }
        }
    }

    private func drawField(ctx: GraphicsContext, size: CGSize, t: TimeInterval, palette: [Color]) {
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
            let color = palette[blade.shadeIndex % palette.count]
            ctx.fill(path, with: .color(color))
        }
    }

    private func wheatShades() -> [Color] {
        let ui = UIColor(Color.wheat)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return Self.shadeOffsets.map { _ in Color.wheat }
        }
        return Self.shadeOffsets.map { offset in
            let newB = max(0, min(1, b + CGFloat(offset)))
            return Color(UIColor(hue: h, saturation: s, brightness: newB, alpha: a))
        }
    }

    private static func makeBlades() -> [Blade] {
        (0..<bladeCount).map { i in
            let t = Double(i) / Double(bladeCount)
            return Blade(
                x: t + Double.random(in: -0.005...0.005),
                widthRatio: Double.random(in: 0.4...1.0),
                heightRatio: Double.random(in: 0.55...1.0),
                phase: -t * 2 * .pi * waves + Double.random(in: -0.4...0.4),
                shadeIndex: Int.random(in: 0..<shadeOffsets.count)
            )
        }
    }

    private struct Blade {
        let x: Double
        let widthRatio: Double
        let heightRatio: Double
        let phase: Double
        let shadeIndex: Int
    }
}

#Preview {
    WheatFieldView()
        .frame(height: 260)
        .background(Color.bg)
}
