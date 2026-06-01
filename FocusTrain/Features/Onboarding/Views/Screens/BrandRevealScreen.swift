import SwiftUI

struct BrandRevealScreen: View {
    @State private var emblemIn = false
    @State private var titleIn = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FT.Palette.brandRail.opacity(0.18))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                Circle()
                    .fill(FT.Palette.bgElevated)
                    .frame(width: 140, height: 140)
                    .overlay(Circle().stroke(FT.Palette.brandRail, lineWidth: 2))
                Image(systemName: "tram.fill")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(FT.Palette.brandRail)
            }
            .scaleEffect(emblemIn ? 1 : 0.6)
            .opacity(emblemIn ? 1 : 0)

            VStack(spacing: 10) {
                Text(NSLocalizedString("onboarding.brand.context", comment: ""))
                    .font(FT.Typography.contextLine)
                    .foregroundStyle(FT.Palette.textSecondary)
                Text("RailFocus")
                    .font(FT.Typography.displayL)
                    .foregroundStyle(FT.Palette.textPrimary)
                Text(NSLocalizedString("onboarding.brand.tagline", comment: ""))
                    .font(FT.Typography.body)
                    .foregroundStyle(FT.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            }
            .opacity(titleIn ? 1 : 0)
            .offset(y: titleIn ? 0 : 12)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { emblemIn = true }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) { titleIn = true }
        }
    }
}
