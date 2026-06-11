import SwiftUI

/// The active-state visual for Tunnel Mode: a soft darkening "tunnel" that
/// settles over the ride, with a glowing arch and a breathing moon glyph.
/// Bound to `InAppTunnelController.isActive` and animated in/out.
struct TunnelHero: View {
    let isActive: Bool

    @State private var breathe = false

    var body: some View {
        ZStack {
            // Vignette dimming — pulls focus inward like entering a tunnel.
            RadialGradient(
                colors: [.clear, FT.Palette.black.opacity(0.85)],
                center: .center,
                startRadius: 60,
                endRadius: 360
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(FT.Palette.white.opacity(0.12))
                        .frame(width: 132, height: 132)
                        .scaleEffect(breathe ? 1.12 : 0.92)
                        .blur(radius: 6)

                    Circle()
                        .stroke(FT.Palette.white.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 96, height: 96)

                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(FT.Palette.white)
                        .shadow(color: FT.Palette.white.opacity(0.6), radius: 16)
                }

                Text(NSLocalizedString("session.tunnel.on", comment: ""))
                    .font(FT.Typography.button)
                    .foregroundStyle(FT.Palette.white)
                    .tracking(0.5)
            }
            .offset(y: -40)
        }
        .opacity(isActive ? 1 : 0)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}
