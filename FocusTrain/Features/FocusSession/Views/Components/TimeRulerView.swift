import SwiftUI

struct TimeRulerView: View {
    let model: DurationPickerModel

    @Environment(\.colorScheme) private var colorScheme

    /// The ruler floats over the map, so its ticks/labels follow the map chrome
    /// (charcoal over a light map, white over a dark one) at the same opacities.
    private var rulerInk: Color {
        model.mapStyle.usesDarkChrome(for: colorScheme) ? .white : Color(hex: 0x1A1A1A)
    }

    private let majorSpacing: CGFloat = 66
    private let fineTicksPerSegment: Int = 6
    private let frameHeight: CGFloat = 62

    private var stepsPerSegment: Int { fineTicksPerSegment + 1 }
    private var fineSpacing: CGFloat { majorSpacing / CGFloat(stepsPerSegment) }

    @State private var dragStartScrollX: CGFloat? = nil   // non-nil while dragging
    @State private var liveScrollX: CGFloat = 0
    @State private var lastFineIndex: Int = 0

    private var maxScrollX: CGFloat {
        CGFloat(max(0, model.destinations.count - 1)) * majorSpacing
    }
    private var a11yValue: String {
        guard let d = model.selectedDestination else { return "" }
        return "\(d.city), \(d.minutes) " + NSLocalizedString("durationPicker.minutes", comment: "")
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let dragging = dragStartScrollX != nil
            let scrollX = dragging ? liveScrollX : CGFloat(model.selectedIndex) * majorSpacing
            let totalFineSteps = max(0, (model.destinations.count - 1) * stepsPerSegment)

            Canvas { ctx, size in
                let midY = size.height / 2

                // Fine ticks (under) — skip positions that coincide with major ticks.
                for j in 0...totalFineSteps {
                    guard j % stepsPerSegment != 0 else { continue }
                    let x = centerX - scrollX + CGFloat(j) * fineSpacing
                    guard x > -20, x < size.width + 20 else { continue }
                    var fine = Path()
                    fine.move(to: CGPoint(x: x, y: midY - 3))
                    fine.addLine(to: CGPoint(x: x, y: midY + 3))
                    ctx.stroke(fine, with: .color(rulerInk.opacity(0.18)), lineWidth: 1.0)
                }

                // Major ticks + labels.
                for (i, dest) in model.destinations.enumerated() {
                    let x = centerX - scrollX + CGFloat(i) * majorSpacing
                    guard x > -60, x < size.width + 60 else { continue }
                    let sel = i == model.selectedIndex
                    var tick = Path()
                    tick.move(to: CGPoint(x: x, y: midY - (sel ? 14 : 10)))
                    tick.addLine(to: CGPoint(x: x, y: midY + (sel ? 14 : 10)))
                    ctx.stroke(tick,
                               with: .color(sel ? FT.Palette.brandRail : rulerInk.opacity(0.4)),
                               lineWidth: sel ? 2.5 : 1.5)
                    let label = Text(dest.durationLabel)
                        .font(.system(size: sel ? 16 : 12, weight: sel ? .bold : .medium))
                        .foregroundColor(rulerInk.opacity(sel ? 1.0 : 0.5))
                    ctx.draw(label, at: CGPoint(x: x, y: midY + 22))
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
                            let start = CGFloat(model.selectedIndex) * majorSpacing
                            dragStartScrollX = start
                            lastFineIndex = Int((start / fineSpacing).rounded())
                            model.beginInteraction(.ruler)
                        }
                        let proposed = (dragStartScrollX ?? 0) - value.translation.width
                        liveScrollX = min(max(proposed, -majorSpacing * 0.4),
                                          maxScrollX + majorSpacing * 0.4)

                        let newFineIndex = Int((liveScrollX / fineSpacing).rounded())
                        if newFineIndex != lastFineIndex {
                            // Major crossings are handled by model.select() below;
                            // here we only fire the soft texture between them.
                            if newFineIndex % stepsPerSegment != 0 {
                                model.fineTick()
                            }
                            lastFineIndex = newFineIndex
                        }

                        model.select(Int((liveScrollX / majorSpacing).rounded()), from: .ruler)
                    }
                    .onEnded { _ in
                        dragStartScrollX = nil
                        lastFineIndex = Int((CGFloat(model.selectedIndex) * majorSpacing / fineSpacing).rounded())
                        model.endInteraction()
                    }
            )
            .animation(dragging ? nil : .spring(response: 0.4, dampingFraction: 0.85),
                       value: model.selectedIndex)
        }
        .frame(height: frameHeight)
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
            Text("\(m.selectedDestination?.minutes ?? 0)m")
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(.white)
            TimeRulerView(model: m)
        }
    }
}
#endif
