import SwiftUI

/// The focus-reason modal the tapped seat morphs into: seat code, prompt and
/// the focus-mode chips. Pure surface — selection state lives in the host
/// (`SeatPickerView`), which commits as soon as either binding becomes non-nil.
struct FocusReasonCard: View {
    let seatCode: String
    @Binding var selectedDefault: FocusMode?
    @Binding var selectedCustomID: UUID?
    let customModes: [CustomFocusMode]
    let onTapAdd: () -> Void
    let onDeleteCustom: (CustomFocusMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("seatPicker.modal.seat", comment: ""), seatCode))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FT.Palette.textSecondary)
                Text(LocalizedStringKey("seatPicker.modal.title"))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(FT.Palette.textPrimary)
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

#Preview {
    ZStack {
        FT.Palette.black.ignoresSafeArea()
        FocusReasonCard(
            seatCode: "01C",
            selectedDefault: .constant(nil),
            selectedCustomID: .constant(nil),
            customModes: [],
            onTapAdd: {},
            onDeleteCustom: { _ in }
        )
        .padding(.horizontal, 24)
    }
}
