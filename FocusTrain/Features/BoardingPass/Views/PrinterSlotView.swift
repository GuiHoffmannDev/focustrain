import SwiftUI

/// The horizontal printer slot from which the boarding pass emerges.
/// Decorative — sits above the ticket card and visually "feeds" the
/// paper out as the print animation runs underneath.
struct PrinterSlotView: View {
    var width: CGFloat

    var body: some View {
        ZStack {
            // Slot body — slightly wider than the ticket, with depth
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.16),
                            Color(white: 0.09)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width + 28, height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.55), radius: 14, y: 6)

            // Inner slit — the actual paper opening
            Capsule()
                .fill(Color.black)
                .frame(width: width + 4, height: 3)
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.8), lineWidth: 0.5)
                        .blur(radius: 0.5)
                )
                .shadow(color: Color.black.opacity(0.8), radius: 1, y: 0.5)

            // Tiny status LED, just for character
            HStack {
                Spacer()
                Circle()
                    .fill(Color(white: 0.45))
                    .frame(width: 4, height: 4)
                    .overlay(
                        Circle()
                            .fill(FT.Palette.brandRail.opacity(0.6))
                            .frame(width: 2.5, height: 2.5)
                    )
                    .padding(.trailing, 14)
            }
            .frame(width: width + 28)
        }
        .frame(width: width + 28, height: 26)
        .allowsHitTesting(false)
    }
}
