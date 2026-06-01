import SwiftUI

struct TimeRulerView: View {
    let model: DurationPickerModel

    private let spacing: CGFloat = 66

    @State private var dragStartScrollX: CGFloat? = nil   // non-nil while dragging
    @State private var liveScrollX: CGFloat = 0

    private var maxScrollX: CGFloat { CGFloat(model.destinations.count - 1) * spacing }
    private var a11yValue: String {
        let d = model.selectedDestination
        return "\(d.city), \(d.minutes) " + NSLocalizedString("durationPicker.minutes", comment: "")
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let dragging = dragStartScrollX != nil
            let scrollX = dragging ? liveScrollX : CGFloat(model.selectedIndex) * spacing

            Canvas { ctx, size in
                let midY = size.height / 2
                for (i, dest) in model.destinations.enumerated() {
                    let x = centerX - scrollX + CGFloat(i) * spacing
                    guard x > -60, x < size.width + 60 else { continue }
                    let sel = i == model.selectedIndex
                    var tick = Path()
                    tick.move(to: CGPoint(x: x, y: midY - (sel ? 18 : 11)))
                    tick.addLine(to: CGPoint(x: x, y: midY + (sel ? 18 : 11)))
                    ctx.stroke(tick,
                               with: .color(.white.opacity(sel ? 1.0 : 0.35)),
                               lineWidth: sel ? 2.5 : 1.5)
                    let label = Text("\(dest.minutes)")
                        .font(.system(size: sel ? 16 : 12, weight: sel ? .bold : .medium))
                        .foregroundColor(.white.opacity(sel ? 1.0 : 0.5))
                    ctx.draw(label, at: CGPoint(x: x, y: midY + 34))
                }
            }
            .overlay(alignment: .top) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(FT.Palette.brandRail)
                    .position(x: centerX, y: 6)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if dragStartScrollX == nil {
                            dragStartScrollX = CGFloat(model.selectedIndex) * spacing
                            model.beginInteraction(.ruler)
                        }
                        let proposed = (dragStartScrollX ?? 0) - value.translation.width
                        liveScrollX = min(max(proposed, -spacing * 0.4), maxScrollX + spacing * 0.4)
                        model.select(Int((liveScrollX / spacing).rounded()), from: .ruler)
                    }
                    .onEnded { _ in
                        dragStartScrollX = nil
                        model.endInteraction()
                    }
            )
            .animation(dragging ? nil : .spring(response: 0.4, dampingFraction: 0.85),
                       value: model.selectedIndex)
        }
        .frame(height: 78)
        .accessibilityElement()
        .accessibilityLabel(Text(NSLocalizedString("durationPicker.ruler.a11yLabel", comment: "")))
        .accessibilityValue(Text(a11yValue))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: model.select(model.selectedIndex + 1, from: .ruler)
            case .decrement: model.select(model.selectedIndex - 1, from: .ruler)
            @unknown default: break
            }
        }
    }
}

#if DEBUG
#Preview("TimeRuler") {
    let m = DurationPickerModel(haptics: NoopDetentService())
    return ZStack {
        FT.Palette.black.ignoresSafeArea()
        VStack(spacing: 24) {
            Text("\(m.selectedDestination.minutes)m").font(.system(size: 40, weight: .heavy))
                .foregroundStyle(.white)
            TimeRulerView(model: m)
        }
    }
}
#endif
