import SwiftUI
import UIKit

/// Horizontal scroll of focus-mode chips. Default modes come first, then any
/// custom presets the user has saved, then a trailing "+" chip that opens the
/// custom-mode sheet. Selection drives both `selectedDefault` and
/// `selectedCustomID` — exactly one of them is non-nil at a time.
struct FocusModeChips: View {
    @Binding var selectedDefault: FocusMode?
    @Binding var selectedCustomID: UUID?
    let customModes: [CustomFocusMode]
    let onTapAdd: () -> Void
    let onDeleteCustom: (CustomFocusMode) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FocusMode.allCases) { mode in
                    defaultChip(mode)
                }
                ForEach(customModes) { mode in
                    customChip(mode)
                }
                addChip
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Default chip

    private func defaultChip(_ mode: FocusMode) -> some View {
        FTGlassChip(
            isSelected: selectedDefault == mode,
            tint: mode.tint,
            selectedScale: 1.03,
            action: { selectedDefault = mode; selectedCustomID = nil }
        ) {
            chipContent(symbol: mode.symbol, text: LocalizedStringKey(mode.displayKey))
        }
    }

    // MARK: - Custom chip

    private func customChip(_ mode: CustomFocusMode) -> some View {
        FTGlassChip(
            isSelected: selectedCustomID == mode.id,
            tint: mode.tint,
            selectedScale: 1.03,
            action: { selectedCustomID = mode.id; selectedDefault = nil }
        ) {
            chipContent(symbol: mode.symbol, text: LocalizedStringKey(mode.name))
        }
        .contextMenu {
            Button(role: .destructive) {
                onDeleteCustom(mode)
            } label: {
                Label(LocalizedStringKey("focusMode.custom.delete"), systemImage: "trash")
            }
        }
    }

    // MARK: - Add chip

    private var addChip: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onTapAdd()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(FT.Palette.textPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.clear)
                    .ftGlassCapsule(interactive: true)
            )
            .overlay(
                Capsule().stroke(FT.Palette.textMuted.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey("focusMode.custom.add")))
    }

    // MARK: - Label

    private func chipContent(symbol: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 14, weight: .semibold))
            Text(text).font(.system(size: 14, weight: .semibold)).lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
