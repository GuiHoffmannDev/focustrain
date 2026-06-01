import SwiftUI

struct RadarDialView: View {
    let model: DurationPickerModel

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let ringR = side / 2 - 26
            let sel = model.selectedDestination

            ZStack {
                // Concentric rings
                ForEach(1...3, id: \.self) { i in
                    Circle()
                        .stroke(FT.Palette.textMuted.opacity(0.18), lineWidth: 1)
                        .frame(width: ringR * 2 * CGFloat(i) / 3, height: ringR * 2 * CGFloat(i) / 3)
                        .position(center)
                }

                // Needle to the selected pin
                Path { p in
                    p.move(to: center)
                    p.addLine(to: point(for: sel.radarDegrees, radius: ringR, center: center))
                }
                .stroke(FT.Palette.brandRail, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: model.selectedIndex)

                // Origin dot
                Circle().fill(FT.Palette.brandRail)
                    .frame(width: 10, height: 10).position(center)

                // Pins
                ForEach(Array(model.destinations.enumerated()), id: \.element.id) { idx, dest in
                    DestinationPin(destination: dest, isSelected: idx == model.selectedIndex)
                        .position(point(for: dest.radarDegrees, radius: ringR, center: center))
                        .onTapGesture {
                            model.beginInteraction(.radar)
                            model.select(idx, from: .radar)
                            model.endInteraction()
                        }
                }
            }
        }
        .frame(height: 280)
    }

    private func point(for degrees: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let r = degrees * .pi / 180
        return CGPoint(x: center.x + radius * cos(r), y: center.y + radius * sin(r))
    }
}

#if DEBUG
#Preview("Radar") {
    let m = DurationPickerModel(haptics: NoopDetentService())
    return ZStack { FT.Palette.black.ignoresSafeArea(); RadarDialView(model: m).padding() }
}
#endif
