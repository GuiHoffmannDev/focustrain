import SwiftUI

struct OnboardingContainerView: View {
    @State private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            FT.Palette.black.ignoresSafeArea()

            VStack(spacing: 24) {
                topBar
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                bottomBar
            }
            .padding(.horizontal, FT.Layout.sideMargin)
            .padding(.vertical, 20)
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            if vm.current != .welcome {
                FTGlassIconButton(
                    systemName: "chevron.left",
                    size: 44,
                    iconSize: 17,
                    foreground: FT.Palette.textSecondary,
                    accessibilityLabel: "common.back"
                ) { vm.back() }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            if vm.current.showsStepIndicator {
                StepIndicator(
                    segments: FT.Layout.stepSegments,
                    activeSegment: vm.current.stepSegment
                )
            } else {
                Color.clear.frame(height: FT.Layout.stepBarHeight)
            }

            Spacer()

            if showsSkip {
                Button(action: { vm.skipToReady() }) {
                    Text(NSLocalizedString("onboarding.skip", comment: ""))
                        .font(FT.Typography.button)
                        .foregroundStyle(FT.Palette.textSecondary)
                        .frame(height: 44)
                        .padding(.horizontal, 14)
                        .background {
                            Capsule()
                                .fill(.clear)
                                .ftGlassCapsule(interactive: true)
                        }
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
    }

    private var showsSkip: Bool {
        switch vm.current {
        case .problem, .solution, .brandReveal, .mapProposal, .ticketPreview:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.current {
        case .welcome:
            WelcomeScreen()
                .id(OnboardingStep.welcome)
        case .problem:
            ProblemScreen()
                .id(OnboardingStep.problem)
        case .solution:
            SolutionScreen()
                .id(OnboardingStep.solution)
        case .brandReveal:
            BrandRevealScreen()
                .id(OnboardingStep.brandReveal)
        case .mapProposal:
            MapPreviewScreen()
                .id(OnboardingStep.mapProposal)
        case .ticketPreview:
            TicketRevealScreen(scenario: vm.selectedScenario)
                .id(OnboardingStep.ticketPreview)
        case .scenarioPicker:
            ScenarioPickerScreen(selection: Binding(
                get: { vm.selectedScenario },
                set: { vm.selectedScenario = $0 }
            ))
            .id(OnboardingStep.scenarioPicker)
        case .quietCarriage:
            QuietCarriageScreen(enabled: Binding(
                get: { vm.quietCarriageEnabled },
                set: { vm.quietCarriageEnabled = $0 }
            ))
            .id(OnboardingStep.quietCarriage)
        case .quietCarriageLoading:
            QuietCarriageLoadingScreen()
                .id(OnboardingStep.quietCarriageLoading)
        case .mapStyleMono:
            MapStyleScreen(
                highlightStyle: .monochrome,
                selection: Binding(get: { vm.selectedMapStyle }, set: { vm.selectedMapStyle = $0 }),
                showLabels: Binding(get: { vm.showLabels }, set: { vm.showLabels = $0 })
            )
            .id(OnboardingStep.mapStyleMono)
        case .mapStyleTerra:
            MapStyleScreen(
                highlightStyle: .terra,
                selection: Binding(get: { vm.selectedMapStyle }, set: { vm.selectedMapStyle = $0 }),
                showLabels: Binding(get: { vm.showLabels }, set: { vm.showLabels = $0 })
            )
            .id(OnboardingStep.mapStyleTerra)
        case .mapStyleStandard:
            MapStyleScreen(
                highlightStyle: .standard,
                selection: Binding(get: { vm.selectedMapStyle }, set: { vm.selectedMapStyle = $0 }),
                showLabels: Binding(get: { vm.showLabels }, set: { vm.showLabels = $0 })
            )
            .id(OnboardingStep.mapStyleStandard)
        case .readyFinal:
            ReadyScreen()
                .id(OnboardingStep.readyFinal)
        }
    }

    private var bottomBar: some View {
        CTAButton(
            title: ctaTitle,
            style: .primary,
            icon: vm.current == .readyFinal ? "sparkles" : "arrow.right",
            isLoading: vm.isLoading
        ) {
            vm.next()
        }
    }

    private var ctaTitle: String {
        switch vm.current {
        case .welcome:      return NSLocalizedString("onboarding.cta.welcome", comment: "")
        case .problem:      return NSLocalizedString("onboarding.cta.problem", comment: "")
        case .solution:     return NSLocalizedString("onboarding.cta.solution", comment: "")
        case .readyFinal:   return NSLocalizedString("onboarding.cta.readyFinal", comment: "")
        default:            return NSLocalizedString("onboarding.cta.continue", comment: "")
        }
    }
}

#Preview {
    OnboardingContainerView()
}
