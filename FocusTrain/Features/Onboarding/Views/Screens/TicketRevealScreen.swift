import SwiftUI

struct TicketRevealScreen: View {
    let scenario: FocusScenario

    @State private var ticketIn = false
    @State private var route: (from: Station, to: Station) = StationPool.randomPair()
    @State private var code: String = String(UUID().uuidString.prefix(8)).uppercased()

    private var departTime: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer().frame(height: 8)

            DisplayKeyword(
                context: NSLocalizedString("onboarding.ticket.context", comment: ""),
                keyword: NSLocalizedString("onboarding.ticket.keyword", comment: ""),
                keywordFont: FT.Typography.displayL
            )

            Spacer()

            HStack {
                Spacer()
                TrainTicketCard(
                    fromCode: route.from.code,
                    toCode: route.to.code,
                    fromName: route.from.city,
                    toName: route.to.city,
                    scenarioTag: NSLocalizedString("scenario.\(scenario.rawValue).title", comment: "").uppercased(),
                    departLabel: departTime,
                    durationLabel: "25 MIN",
                    ticketCode: code
                )
                .scaleEffect(ticketIn ? 1 : 0.9)
                .opacity(ticketIn ? 1 : 0)
                Spacer()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                ticketIn = true
            }
            let h = UINotificationFeedbackGenerator()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                h.notificationOccurred(.success)
            }
        }
    }
}
