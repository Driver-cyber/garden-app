import SwiftUI
import UIKit

struct WheatFieldView: View {
    private static let bladeCount = 80
    private static let waves = 1.6
    private static let periodSeconds: Double = 3.3
    private static let maxAngleDegrees: Double = 6

    /// (hueShift, satMultiplier, brightnessMultiplier) — varies the base wheat color
    /// across hue + saturation + brightness for a painterly, multi-toned field.
    private static let shadeRecipes: [(hueShift: Double, sat: Double, bri: Double)] = [
        (-0.018, 1.05, 0.78),  // amber, deep
        (-0.008, 1.00, 0.92),  // standard wheat
        ( 0.000, 0.80, 1.05),  // pale wheat
        ( 0.010, 1.10, 0.86),  // golden
        ( 0.030, 0.65, 1.02),  // olive-leaning, soft
    ]

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
            let width = 3.0 + blade.widthRatio * 3.0
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
            return Self.shadeRecipes.map { _ in Color.wheat }
        }
        return Self.shadeRecipes.map { recipe in
            var newH = h + CGFloat(recipe.hueShift)
            if newH < 0 { newH += 1 }
            if newH > 1 { newH -= 1 }
            let newS = max(0, min(1, s * CGFloat(recipe.sat)))
            let newB = max(0, min(1, b * CGFloat(recipe.bri)))
            return Color(UIColor(hue: newH, saturation: newS, brightness: newB, alpha: a))
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
                shadeIndex: Int.random(in: 0..<shadeRecipes.count)
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
