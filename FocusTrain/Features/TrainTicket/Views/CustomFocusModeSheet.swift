import SwiftUI
import UIKit

/// Sheet for creating a custom focus-mode preset: name + SF Symbol + color.
/// On save, calls `onSave` with the new preset and dismisses.
struct CustomFocusModeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (CustomFocusMode) -> Void

    @State private var name: String = ""
    @State private var selectedSymbol: String = Self.symbolChoices[0]
    @State private var selectedTintHex: UInt32 = Self.colorChoices[0]

    private static let symbolChoices: [String] = [
        "scope",
        "laptopcomputer",
        "leaf.fill",
        "book.fill",
        "figure.run",
        "paintbrush.fill",
        "music.note",
        "chevron.left.forwardslash.chevron.right",
        "headphones",
        "pencil.and.outline",
        "camera.fill",
        "sparkles"
    ]

    private static let colorChoices: [UInt32] = [
        0xC5D5C0, // sage
        0xC5C5E0, // lavender
        0xB8D5C5, // mint
        0xD5D0B8, // cream
        0xE0C5D0, // blush
        0xE0A458  // brass
    ]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        let length = trimmedName.count
        return length >= 1 && length <= 24
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FT.Palette.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        nameSection
                        symbolSection
                        colorSection
                        preview
                    }
                    .padding(24)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle(LocalizedStringKey("focusMode.custom.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("common.cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(FT.Palette.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("focusMode.custom.save")) {
                        save()
                    }
                    .foregroundStyle(canSave ? FT.Palette.brandRail : FT.Palette.textMuted)
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(LocalizedStringKey("focusMode.custom.name"))
            TextField("", text: $name, prompt: Text(LocalizedStringKey("focusMode.custom.name.placeholder")).foregroundStyle(FT.Palette.textMuted))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .foregroundStyle(FT.Palette.textPrimary)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(FT.Palette.bgElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(FT.Palette.textMuted.opacity(0.3), lineWidth: 1)
                )
        }
    }

    private var symbolSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(LocalizedStringKey("focusMode.custom.icon"))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(Self.symbolChoices, id: \.self) { symbol in
                    symbolCell(symbol)
                }
            }
        }
    }

    private func symbolCell(_ symbol: String) -> some View {
        let isSelected = symbol == selectedSymbol
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                selectedSymbol = symbol
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isSelected ? FT.Palette.ink : FT.Palette.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? Color(hex: UInt32(selectedTintHex)) : FT.Palette.bgElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isSelected ? FT.Palette.brandRail : FT.Palette.textMuted.opacity(0.25),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(LocalizedStringKey("focusMode.custom.color"))
            HStack(spacing: 12) {
                ForEach(Self.colorChoices, id: \.self) { hex in
                    colorSwatch(hex)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func colorSwatch(_ hex: UInt32) -> some View {
        let isSelected = hex == selectedTintHex
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                selectedTintHex = hex
            }
        } label: {
            Circle()
                .fill(Color(hex: UInt32(hex)))
                .frame(width: 38, height: 38)
                .overlay(
                    Circle()
                        .stroke(FT.Palette.brandRail, lineWidth: isSelected ? 3 : 0)
                )
                .scaleEffect(isSelected ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(LocalizedStringKey("focusMode.custom.preview"))
            HStack(spacing: 8) {
                Image(systemName: selectedSymbol)
                    .font(.system(size: 14, weight: .semibold))
                Text(trimmedName.isEmpty ? NSLocalizedString("focusMode.custom.name.placeholder", comment: "") : trimmedName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(FT.Palette.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(Color(hex: UInt32(selectedTintHex)))
            )
        }
    }

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 13, weight: .semibold))
            .textCase(.uppercase)
            .foregroundStyle(FT.Palette.textSecondary)
            .tracking(0.6)
    }

    // MARK: - Actions

    private func save() {
        guard canSave else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let mode = CustomFocusMode(
            name: trimmedName,
            symbol: selectedSymbol,
            tintHex: selectedTintHex
        )
        onSave(mode)
        dismiss()
    }
}