import SwiftUI

struct DurationPickerView: View {
    /// Called with the freshly-built ticket when the user departs.
    var onDepart: (Ticket) -> Void
    var onBack: () -> Void

    @State private var model = DurationPickerModel()
    @State private var resolver = CurrentCityResolver()
    @State private var appeared = false
    @Environment(HomeCityStore.self) private var homeCityStore

    @AppStorage("defaultMapStyle") private var rawMapStyle: String = MapStyle.monochrome.rawValue
    @AppStorage("mapShowLabels") private var showLabels: Bool = true

    var body: some View {
        ZStack {
            FT.Palette.black.ignoresSafeArea()

            // A dessaturação do estilo monocromático é feita DENTRO do mapa
            // (subview abaixo dos pins), pra não apagar a cor da pill do destino.
            DestinationMapView(model: model)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)

            // Scrim topo (título) para legibilidade.
            VStack {
                LinearGradient(colors: [FT.Palette.black.opacity(0.6), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 180)
                Spacer()
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
                loadedControls
                    .padding(.bottom, 12)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // Plain button: the iOS 26 toolbar supplies the Liquid Glass
                // chrome; a custom background here would double it.
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(FT.Palette.white)
                }
                .accessibilityLabel(Text("common.back"))
            }
        }
        .onAppear {
            model.prepareHaptics()
            resolver.bootstrap()
            if let m = MapStyle(rawValue: rawMapStyle) { model.mapStyle = m }
            model.mapShowLabels = showLabels
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { appeared = true }
        }
        .onChange(of: resolver.cityName) { _, name in
            if let name, let coord = resolver.coordinate {
                model.setGPSOrigin(
                    city: name,
                    countryCode: resolver.countryCode,
                    coordinate: coord
                )
            }
        }
        .onChange(of: homeCityStore.manualCity) { _, _ in
            model.refreshFromHomeCityStore()
        }
        .onChange(of: rawMapStyle) { _, raw in
            if let m = MapStyle(rawValue: raw) { model.mapStyle = m }
        }
        .onChange(of: showLabels) { _, v in
            model.mapShowLabels = v
        }
    }

    // MARK: - Bottom controls

    private var loadedControls: some View {
        VStack(spacing: 16) {
            TimeRulerView(model: model)

            DestinationCardStripView(model: model)
                .padding(.bottom, 6)

            CTAButton(title: NSLocalizedString("compose.depart", comment: ""),
                      style: .primary, icon: "arrow.right",
                      action: { if let t = model.makeTicket() { onDepart(t) } })
                .padding(.horizontal, FT.Layout.sideMargin)
        }
    }
}
