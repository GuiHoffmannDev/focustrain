import SwiftUI

/// Floating card shown once the user has picked a seat. Shows the selected
/// seat code and prompts for an intention (focus mode) via embedded chips.
struct SeatConfirmCard: View {
    let seatCode: String
    @Binding var selectedDefault: FocusMode?
    @Binding var selectedCustomID: UUID?
    let customModes: [CustomFocusMode]
    let onTapAdd: () -> Void
    let onDeleteCustom: (CustomFocusMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("seatPicker.confirm.title", comment: ""), seatCode))
                    .font(FT.Typography.sectionTitle)
                    .foregroundStyle(FT.Palette.textPrimary)
                Text(LocalizedStringKey("seatPicker.confirm.subtitle"))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(FT.Palette.textSecondary)
            }

            FocusModeChips(
                selectedDefault: $selectedDefault,
                selectedCustomID: $selectedCustomID,
                customModes: customModes,
                onTapAdd: onTapAdd,
                onDeleteCustom: onDeleteCustom
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.clear)
                .ftGlassRounded(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(FT.Palette.textMuted.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
    }
}
