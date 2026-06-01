import SwiftUI

/// Bottom-sheet Settings adapted to the rail metaphor. Holds its own
/// NavigationStack so sub-screens push inside the sheet.
struct SettingsSheet: View {
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    SubscribeBanner()
                    RewardsBanner()
                    GeneralSection()
                    GuideSection()
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, FT.Layout.sideMargin)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .background(Color.clear)
            .navigationTitle(Text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(FT.Palette.textPrimary)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle().fill(FT.Palette.bgElevated.opacity(0.6))
                            )
                    }
                }
            }
            .tint(FT.Palette.brandRail)
        }
    }
}

// MARK: - Banners

private struct SubscribeBanner: View {
    var body: some View {
        Button(action: {}) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("settings.banner.subscribe.title")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(FT.Palette.white)
                        .multilineTextAlignment(.leading)
                    Text("settings.banner.subscribe.subtitle")
                        .font(FT.Typography.caption)
                        .foregroundStyle(FT.Palette.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Text("settings.banner.subscribe.cta")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FT.Palette.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule().fill(FT.Palette.white)
                    )
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                FT.Palette.brandBrass,
                                Color(hex: 0x8B5E2A)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(FT.Palette.white.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct RewardsBanner: View {
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(FT.Palette.brandBrass.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FT.Palette.brandBrass)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.banner.rewards.title")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FT.Palette.textPrimary)
                    Text("settings.banner.rewards.subtitle")
                        .font(FT.Typography.caption)
                        .foregroundStyle(FT.Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FT.Palette.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(FT.Palette.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sections

private struct GeneralSection: View {
    @AppStorage("quietCarriageEnabled") private var quietCarriageEnabled: Bool = false
    @AppStorage("ft.notifications.enabled") private var notificationsEnabled: Bool = true

    var body: some View {
        SettingsSection(titleKey: "settings.section.general") {
            ToggleRow(icon: "speaker.slash.fill",
                      titleKey: "settings.row.quietMode",
                      isOn: $quietCarriageEnabled)
            Divider().background(FT.Palette.white.opacity(0.06))
            NavRow(icon: "map.fill", titleKey: "settings.row.mapStyle") {
                MapStyleDetailView()
            }
            Divider().background(FT.Palette.white.opacity(0.06))
            NavRow(icon: "leaf.fill", titleKey: "settings.row.scenarios") {
                ScenariosDetailView()
            }
            Divider().background(FT.Palette.white.opacity(0.06))
            ToggleRow(icon: "bell.fill",
                      titleKey: "settings.row.notifications",
                      isOn: $notificationsEnabled)
            Divider().background(FT.Palette.white.opacity(0.06))
            NavRow(icon: "waveform", titleKey: "settings.row.sound") {
                SoundHapticsDetailView()
            }
            Divider().background(FT.Palette.white.opacity(0.06))
            NavRow(icon: "tram.fill", titleKey: "settings.row.inRide") {
                InRideDetailView()
            }
            Divider().background(FT.Palette.white.opacity(0.06))
            NavRow(icon: "ruler.fill", titleKey: "settings.row.units") {
                UnitsDetailView()
            }
            Divider().background(FT.Palette.white.opacity(0.06))
            NavRow(icon: "globe", titleKey: "settings.row.language") {
                LanguageDetailView()
            }
        }
    }
}

private struct GuideSection: View {
    var body: some View {
        SettingsSection(titleKey: "settings.section.guide") {
            HStack(spacing: 12) {
                rowIcon("icloud.fill")
                Text("settings.row.iCloud")
                    .font(FT.Typography.body)
                    .foregroundStyle(FT.Palette.textPrimary)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FT.Palette.success)
                    Text("settings.iCloud.synced")
                        .font(FT.Typography.caption)
                        .foregroundStyle(FT.Palette.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)

            Divider().background(FT.Palette.white.opacity(0.06))
            NavRow(icon: "info.circle.fill", titleKey: "settings.row.about") {
                AboutDetailView()
            }
            Divider().background(FT.Palette.white.opacity(0.06))
            NavRow(icon: "doc.text.fill", titleKey: "settings.row.terms") {
                TermsDetailView()
            }
        }
    }
}

// MARK: - Shared row primitives

private struct SettingsSection<Content: View>: View {
    let titleKey: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleKey)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FT.Palette.textMuted)
                .textCase(.uppercase)
                .padding(.leading, 6)

            VStack(spacing: 0) { content }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(FT.Palette.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

@ViewBuilder
private func rowIcon(_ system: String) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(FT.Palette.bgElevated.opacity(0.7))
            .frame(width: 30, height: 30)
        Image(systemName: system)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(FT.Palette.textPrimary)
    }
}

private struct ToggleRow: View {
    let icon: String
    let titleKey: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            rowIcon(icon)
            Text(titleKey)
                .font(FT.Typography.body)
                .foregroundStyle(FT.Palette.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(FT.Palette.brandRail)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct NavRow<Destination: View>: View {
    let icon: String
    let titleKey: LocalizedStringKey
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                rowIcon(icon)
                Text(titleKey)
                    .font(FT.Typography.body)
                    .foregroundStyle(FT.Palette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FT.Palette.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail screens

private struct DetailScaffold<Content: View>: View {
    let titleKey: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding(.horizontal, FT.Layout.sideMargin)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .navigationTitle(Text(titleKey))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MapStyleDetailView: View {
    @AppStorage("defaultMapStyle") private var rawStyle: String = MapStyle.monochrome.rawValue
    @AppStorage("mapShowLabels") private var showLabels: Bool = true

    var body: some View {
        DetailScaffold(titleKey: "settings.row.mapStyle") {
            MapStyleSelector(
                selection: Binding(
                    get: { MapStyle(rawValue: rawStyle) ?? .monochrome },
                    set: { rawStyle = $0.rawValue }
                ),
                showLabels: $showLabels
            )
        }
    }
}

private struct ScenariosDetailView: View {
    @AppStorage("defaultScenario") private var rawScenario: String = FocusScenario.forest.rawValue

    var body: some View {
        DetailScaffold(titleKey: "settings.row.scenarios") {
            VStack(spacing: 10) {
                ForEach(FocusScenario.allCases) { scenario in
                    Button {
                        rawScenario = scenario.rawValue
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(scenario.tint.opacity(0.25))
                                    .frame(width: 38, height: 38)
                                Image(systemName: scenario.symbol)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(scenario.tint)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey(scenario.displayKey))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(FT.Palette.textPrimary)
                                Text(LocalizedStringKey(scenario.subtitleKey))
                                    .font(FT.Typography.caption)
                                    .foregroundStyle(FT.Palette.textSecondary)
                            }
                            Spacer()
                            if rawScenario == scenario.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(FT.Palette.brandRail)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    rawScenario == scenario.rawValue
                                        ? FT.Palette.brandRail.opacity(0.6)
                                        : FT.Palette.white.opacity(0.06),
                                    lineWidth: rawScenario == scenario.rawValue ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct SoundHapticsDetailView: View {
    @AppStorage("ft.sound.departure") private var soundOnDeparture: Bool = true
    @AppStorage("ft.haptics.duringRide") private var hapticsDuringRide: Bool = true

    var body: some View {
        DetailScaffold(titleKey: "settings.row.sound") {
            VStack(spacing: 0) {
                ToggleRow(icon: "speaker.wave.2.fill",
                          titleKey: "settings.sound.departureToggle",
                          isOn: $soundOnDeparture)
                Divider().background(FT.Palette.white.opacity(0.06))
                ToggleRow(icon: "iphone.radiowaves.left.and.right",
                          titleKey: "settings.sound.hapticsToggle",
                          isOn: $hapticsDuringRide)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(FT.Palette.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

private struct InRideDetailView: View {
    @AppStorage("ft.inRide.showDistance") private var showDistance: Bool = true
    @AppStorage("ft.inRide.showSpeed") private var showSpeed: Bool = false

    var body: some View {
        DetailScaffold(titleKey: "settings.row.inRide") {
            VStack(spacing: 0) {
                ToggleRow(icon: "ruler",
                          titleKey: "settings.inRide.distance",
                          isOn: $showDistance)
                Divider().background(FT.Palette.white.opacity(0.06))
                ToggleRow(icon: "gauge.with.dots.needle.67percent",
                          titleKey: "settings.inRide.speed",
                          isOn: $showSpeed)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(FT.Palette.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

private struct UnitsDetailView: View {
    @AppStorage("unit") private var unit: String = "km"

    var body: some View {
        DetailScaffold(titleKey: "settings.row.units") {
            PickerCard(selection: $unit, options: [
                ("km", "settings.units.km"),
                ("mi", "settings.units.mi")
            ])
        }
    }
}

private struct LanguageDetailView: View {
    @AppStorage("appLanguage") private var language: String = "system"

    var body: some View {
        DetailScaffold(titleKey: "settings.row.language") {
            VStack(alignment: .leading, spacing: 12) {
                PickerCard(selection: $language, options: [
                    ("system", "settings.language.system"),
                    ("pt-BR", "settings.language.pt"),
                    ("en", "settings.language.en")
                ])
                Text("settings.language.restartHint")
                    .font(FT.Typography.caption)
                    .foregroundStyle(FT.Palette.textMuted)
                    .padding(.horizontal, 6)
            }
        }
    }
}

private struct PickerCard: View {
    @Binding var selection: String
    let options: [(value: String, key: LocalizedStringKey)]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element.value) { idx, option in
                Button {
                    selection = option.value
                } label: {
                    HStack {
                        Text(option.key)
                            .font(FT.Typography.body)
                            .foregroundStyle(FT.Palette.textPrimary)
                        Spacer()
                        if selection == option.value {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(FT.Palette.brandRail)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if idx < options.count - 1 {
                    Divider().background(FT.Palette.white.opacity(0.06))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(FT.Palette.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct AboutDetailView: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        DetailScaffold(titleKey: "settings.row.about") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(FT.Palette.brandRail)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("app.name")
                            .font(FT.Typography.sectionTitle)
                            .foregroundStyle(FT.Palette.textPrimary)
                        Text("settings.about.versionLabel \(version)")
                            .font(FT.Typography.caption)
                            .foregroundStyle(FT.Palette.textSecondary)
                    }
                }
                Text("settings.about.credits")
                    .font(FT.Typography.body)
                    .foregroundStyle(FT.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(FT.Palette.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

private struct TermsDetailView: View {
    var body: some View {
        DetailScaffold(titleKey: "settings.row.terms") {
            Text("settings.terms.placeholder")
                .font(FT.Typography.body)
                .foregroundStyle(FT.Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(FT.Palette.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        SettingsSheet(onClose: {})
            .presentationDetents([.fraction(0.7), .large])
            .presentationBackground(.ultraThinMaterial)
    }
}
