import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Composes the boarding pass body + stub on a procedural dot-matrix map,
/// and routes a left→right drag along the perforation into a ragged tear
/// animation backed by `TearHapticsService`.
struct TearableTicketView: View {
    let display: BoardingPassDisplay
    let interactive: Bool
    let onTearComplete: () -> Void
    let onCancel: () -> Void

    @State private var tearProgress: CGFloat = 0
    @State private var dragActive = false
    @State private var completed = false
    @State private var lastDragX: CGFloat = 0
    @State private var lastDragTime: Date = .now
    @State private var lastVelocity: CGFloat = 0

    private let haptics: TearHapticsService = TearHaptics.make()
    private let seed: UInt32

    init(display: BoardingPassDisplay,
         interactive: Bool,
         onTearComplete: @escaping () -> Void,
         onCancel: @escaping () -> Void) {
        self.display = display
        self.interactive = interactive
        self.onTearComplete = onTearComplete
        self.onCancel = onCancel
        self.seed = UInt32(truncatingIfNeeded: UInt(bitPattern: display.code.hashValue))
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let perforationY = size.height * 0.58
            let separation: CGFloat = completed ? max(size.height * 0.6, 220) : 0

            ZStack {
                // Upper half (body + map background), masked along the torn edge
                ticketLayer(size: size, perforationY: perforationY)
                    .mask(TornEdgePath(
                        progress: tearProgress,
                        perforationY: perforationY,
                        amplitude: 7,
                        seed: seed,
                        side: .upper
                    ))
                    .offset(y: -separation / 2)
                    .rotationEffect(.degrees(completed ? -2.5 : 0),
                                    anchor: .topLeading)

                // Lower half (stub + map background), same path, opposite side
                ticketLayer(size: size, perforationY: perforationY)
                    .mask(TornEdgePath(
                        progress: tearProgress,
                        perforationY: perforationY,
                        amplitude: 7,
                        seed: seed,
                        side: .lower
                    ))
                    .offset(y: separation / 2)
                    .rotationEffect(.degrees(completed ? 1.8 : 0),
                                    anchor: .bottomTrailing)

                // Perforation dashed guide (only while intact-ish)
                PerforationPath()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(FT.Palette.Ticket.perforation.opacity(1 - Double(tearProgress)))
                    .frame(height: 1)
                    .position(x: size.width / 2, y: perforationY)
                    .allowsHitTesting(false)

                // Hint chevron — fades in once printing settles, fades out as user tears
                if interactive && !completed {
                    tearHint(width: size.width, y: perforationY)
                        .opacity(dragActive ? 0 : max(0, 0.7 - Double(tearProgress) * 1.5))
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .gesture(interactive ? tearGesture(width: size.width, perforationY: perforationY) : nil)
        }
        .onAppear { haptics.prepare() }
    }

    // MARK: - Layers

    @ViewBuilder
    private func ticketLayer(size: CGSize, perforationY: CGFloat) -> some View {
        ZStack {
            // Card fill
            BoardingPassShape(notchY: perforationY)
                .fill(FT.Palette.Ticket.card)

            // Map watermark, clipped to the card silhouette
            DotMatrixMapView(tint: FT.Palette.Ticket.mapTint)
                .opacity(0.55)
                .clipShape(BoardingPassShape(notchY: perforationY))

            // Content (whole ticket, both halves stack vertically inside the card)
            VStack(spacing: 0) {
                TicketBodyView(display: display)
                    .frame(height: perforationY, alignment: .top)
                TicketStubView(display: display)
                    .frame(height: size.height - perforationY, alignment: .top)
            }

            // Subtle outline
            BoardingPassShape(notchY: perforationY)
                .stroke(FT.Palette.Ticket.outline, lineWidth: 1)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: Color.black.opacity(0.45), radius: 18, y: 10)
    }

    private func tearHint(width: CGFloat, y: CGFloat) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
            Text("DESLIZE PARA EMBARCAR")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(1.2)
        }
        .foregroundStyle(FT.Palette.Ticket.hint)
        .position(x: width / 2, y: y + 18)
        .allowsHitTesting(false)
    }

    // MARK: - Gesture

    private func tearGesture(width: CGFloat, perforationY: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .local)
            .onChanged { value in
                guard !completed else { return }
                // Only respond to drags that begin near the perforation line.
                if !dragActive {
                    guard abs(value.startLocation.y - perforationY) < 50 else { return }
                    dragActive = true
                    lastDragX = value.startLocation.x
                    lastDragTime = .now
                    haptics.startTear()
                }
                let x = max(0, min(width, value.location.x))
                let progress = x / max(1, width)
                let now = Date()
                let dt = max(0.008, now.timeIntervalSince(lastDragTime))
                let velocity = (x - lastDragX) / CGFloat(dt)
                lastDragX = x
                lastDragTime = now
                lastVelocity = velocity
                tearProgress = progress
                haptics.updateTear(progress: progress, velocity: velocity)
            }
            .onEnded { _ in
                guard dragActive, !completed else {
                    dragActive = false
                    return
                }
                dragActive = false
                if tearProgress >= 0.8 {
                    confirmTear()
                } else {
                    cancelTear()
                }
            }
    }

    private func confirmTear() {
        haptics.completeTear()
        withAnimation(.easeOut(duration: 0.18)) {
            tearProgress = 1.0
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.05)) {
            completed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            onTearComplete()
        }
    }

    private func cancelTear() {
        haptics.cancelTear()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            tearProgress = 0
        }
        onCancel()
    }
}
