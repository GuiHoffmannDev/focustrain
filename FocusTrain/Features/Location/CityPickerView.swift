import SwiftUI

/// Search-as-you-type picker over the bundled GeoNames catalog. Writes the
/// chosen city into `HomeCityStore`, which the rest of the app observes. Lives
/// in the Settings stack and as a fallback when GPS is denied.
struct CityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HomeCityStore.self) private var homeCityStore

    @State private var query: String = ""
    @State private var results: [City] = []
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            FT.Palette.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                searchField
                Divider().background(FT.Palette.strokeHairline)
                content
            }
        }
        .navigationTitle(Text("cityPicker.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: query) { _, newValue in
            scheduleSearch(for: newValue)
        }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FT.Palette.textMuted)
            TextField("",
                      text: $query,
                      prompt: Text("cityPicker.search.placeholder")
                        .foregroundStyle(FT.Palette.textMuted))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(FT.Typography.body)
                .foregroundStyle(FT.Palette.textPrimary)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FT.Palette.textMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.clear)
                .ftGlassRounded(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(FT.Palette.strokeHairline, lineWidth: 1)
        )
        .padding(.horizontal, FT.Layout.sideMargin)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if query.trimmingCharacters(in: .whitespaces).count < 2 {
            emptyState(textKey: "cityPicker.empty.short")
        } else if results.isEmpty {
            emptyState(textKey: "cityPicker.empty.noResults")
        } else {
            resultsList
        }
    }

    private func emptyState(textKey: LocalizedStringKey) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(FT.Palette.textMuted.opacity(0.5))
            Text(textKey)
                .font(FT.Typography.caption)
                .foregroundStyle(FT.Palette.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, FT.Layout.sideMargin)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(results, id: \.geonameId) { city in
                    row(for: city)
                    Divider().background(FT.Palette.strokeHairline)
                }
            }
            .padding(.horizontal, FT.Layout.sideMargin)
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func row(for city: City) -> some View {
        Button {
            homeCityStore.setManualCity(HomeCity(city: city))
            dismiss()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(city.name)
                            .font(FT.Typography.body)
                            .foregroundStyle(FT.Palette.textPrimary)
                        Text("·")
                            .foregroundStyle(FT.Palette.textMuted)
                        Text(city.countryCode)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FT.Palette.textSecondary)
                    }
                    Text(populationLabel(city.population))
                        .font(FT.Typography.caption)
                        .foregroundStyle(FT.Palette.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FT.Palette.textMuted)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func populationLabel(_ pop: Int) -> String {
        if pop >= 1_000_000 {
            return String(format: "%.1fM", Double(pop) / 1_000_000)
        }
        if pop >= 1_000 {
            return String(format: "%.0fk", Double(pop) / 1_000)
        }
        return "\(pop)"
    }

    // MARK: - Search

    private func scheduleSearch(for newQuery: String) {
        searchTask?.cancel()
        let trimmed = newQuery.trimmingCharacters(in: .whitespaces)
        if trimmed.count < 2 {
            results = []
            return
        }
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            if Task.isCancelled { return }
            let hits = await CityDatabase.shared.search(query: trimmed, limit: 50)
            if Task.isCancelled { return }
            results = hits
        }
    }
}
