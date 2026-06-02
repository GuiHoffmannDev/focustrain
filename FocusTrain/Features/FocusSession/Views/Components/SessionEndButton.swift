import SwiftUI

/// Isolated top-right X. Owns its own confirmation-dialog state so the
/// parent `SessionView` body stays clean.
struct SessionEndButton: View {
    var onEnd: () -> Void

    @State private var showConfirm = false

    var body: some View {
        Button {
            showConfirm = true
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(FT.Palette.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(FT.Palette.black.opacity(0.5)))
                .overlay(Circle().stroke(FT.Palette.textMuted.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(NSLocalizedString("session.end", comment: "End the ride")))
        .confirmationDialog(
            NSLocalizedString("session.end", comment: ""),
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("session.end", comment: ""), role: .destructive, action: onEnd)
            Button(NSLocalizedString("common.back", comment: ""), role: .cancel) {}
        }
    }
}

#Preview {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionEndButton(onEnd: {})
    }
}
