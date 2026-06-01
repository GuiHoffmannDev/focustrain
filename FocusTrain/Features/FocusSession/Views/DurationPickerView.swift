import SwiftUI

struct DurationPickerView: View {
    /// Called with the freshly-built ticket when the user departs.
    var onDepart: (Ticket) -> Void
    var onBack: () -> Void

    @State private var model = DurationPickerModel()
    @State private var resolver = CurrentCityResolver()
    @State private var appeared = false

    var body: some View {
        ZStack {
            FT.Palette.black.ignoresSafeArea()

            DestinationMapView(model: model)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)

            // Scrim topo (título) + base (controles) para legibilidade.
            VStack {
                LinearGradient(colors: [FT.Palette.black.opacity(0.6), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 180)
                Spacer()
                LinearGradient(colors: [.clear, FT.Palette.black.opacity(0.85), FT.Palette.black],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 360)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Título sobre o mapa.
            VStack(alignment: .leading, spacing: 0) {
                Text(NSLocalizedString("durationPicker.title", comment: ""))
                    .font(FT.Typography.sectionTitle)
                    .foregroundStyle(FT.Palette.white)
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 12)
                Spacer()
            }
            .allowsHitTesting(false)

            // Controles fixos embaixo.
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(model.selectedDestination.minutes)")
                            .font(.system(size: 44, weight: .heavy))
                            .contentTransition(.numericText())
                        Text(NSLocalizedString("durationPicker.minutes", comment: ""))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(FT.Palette.textSecondary)
                    }
                    .foregroundStyle(FT.Palette.white)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: model.selectedIndex)

                    TimeRulerView(model: model)

                    ScenarioChips(selection: Binding(
                        get: { model.scenario },
                        set: { model.scenario = $0 }
                    ))
                    .padding(.horizontal, FT.Layout.sideMargin)

                    CTAButton(title: NSLocalizedString("compose.depart", comment: ""),
                              style: .primary, icon: "arrow.right",
                              action: { onDepart(model.makeTicket()) })
                        .padding(.horizontal, FT.Layout.sideMargin)
                }
                .padding(.bottom, 12)
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FT.Palette.white)
                }
            }
        }
        .onAppear {
            model.prepareHaptics()
            resolver.bootstrap()
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { appeared = true }
        }
        .onChange(of: resolver.cityName) { _, name in
            if let name, let coord = resolver.coordinate {
                model.setOrigin(city: name, coordinate: coord)
            }
        }
    }
}
