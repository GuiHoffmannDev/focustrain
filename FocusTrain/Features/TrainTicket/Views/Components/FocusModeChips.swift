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
        let isSelected = selectedDefault == mode
        return Button {
            tap {
                selectedDefault = mode
                selectedCustomID = nil
            }
        } label: {
            chipLabel(symbol: mode.symbol, text: LocalizedStringKey(mode.displayKey), tint: mode.tint, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom chip

    private func customChip(_ mode: CustomFocusMode) -> some View {
        let isSelected = selectedCustomID == mode.id
        return Button {
            tap {
                selectedCustomID = mode.id
                selectedDefault = nil
            }
        } label: {
            chipLabel(symbol: mode.symbol, text: LocalizedStringKey(mode.name), tint: mode.tint, isSelected: isSelected)
        }
        .buttonStyle(.plain)
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
                Capsule().fill(FT.Palette.bgElevated.opacity(0.6))
            )
            .overlay(
                Capsule().stroke(FT.Palette.textMuted.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey("focusMode.custom.add")))
    }

    // MARK: - Label

    private func chipLabel(symbol: String, text: LocalizedStringKey, tint: Color, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(FT.Palette.ink)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule().fill(tint)
        )
        .overlay(
            Capsule().stroke(
                isSelected ? FT.Palette.brandRail : Color.clear,
                lineWidth: 3
            )
        )
        .scaleEffect(isSelected ? 1.04 : 1.0)
    }

    private func tap(_ apply: () -> Void) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            apply()
        }
    }
}