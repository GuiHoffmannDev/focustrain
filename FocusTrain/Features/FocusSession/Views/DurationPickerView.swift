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
            RadialGradient(colors: [FT.Palette.brandRail.opacity(0.10), .clear],
                           center: .top, startRadius: 0, endRadius: 420)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text(NSLocalizedString("durationPicker.title", comment: ""))
                        .font(FT.Typography.sectionTitle)
                        .foregroundStyle(FT.Palette.white)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 12)

                    RadarDialView(model: model)
                        .opacity(appeared ? 1 : 0).scaleEffect(appeared ? 1 : 0.96)

                    VStack(spacing: 10) {
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
                    }
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)

                    DestinationCarouselView(model: model)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 18)

                    VStack(alignment: .leading, spacing: 14) {
                        Text(NSLocalizedString("compose.scenario.title", comment: "").uppercased())
                            .font(.system(size: 12, weight: .bold)).tracking(1.5)
                            .foregroundStyle(FT.Palette.textMuted)
                        // model is a @State @Observable reference; an explicit Binding
                        // avoids the @Bindable-local/`return` dance in `body`.
                        ScenarioChips(selection: Binding(
                            get: { model.scenario },
                            set: { model.scenario = $0 }
                        ))
                    }
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
                }
                .padding(.horizontal, FT.Layout.sideMargin)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }

            VStack {
                Spacer()
                CTAButton(title: NSLocalizedString("compose.depart", comment: ""),
                          style: .primary, icon: "arrow.right",
                          action: { onDepart(model.makeTicket()) })
                    .padding(.horizontal, FT.Layout.sideMargin).padding(.bottom, 12)
                    .background(
                        LinearGradient(colors: [FT.Palette.black.opacity(0), FT.Palette.black],
                                       startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea().allowsHitTesting(false)
                    )
            }
            .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 24)
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
