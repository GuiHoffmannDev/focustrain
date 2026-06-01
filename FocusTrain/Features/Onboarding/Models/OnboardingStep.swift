import Foundation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome              = 0
    case problem              = 1
    case solution             = 2
    case brandReveal          = 3
    case mapProposal          = 4
    case ticketPreview        = 5
    case scenarioPicker       = 6
    case quietCarriage        = 7
    case quietCarriageLoading = 8
    case mapStyleMono         = 9
    case mapStyleTerra        = 10
    case mapStyleStandard     = 11
    case readyFinal           = 12

    var id: Int { rawValue }

    static var total: Int { allCases.count }

    var showsStepIndicator: Bool {
        rawValue >= OnboardingStep.ticketPreview.rawValue
    }

    var stepSegment: Int {
        switch self {
        case .ticketPreview, .scenarioPicker:           return 0
        case .quietCarriage, .quietCarriageLoading:     return 1
        case .mapStyleMono, .mapStyleTerra, .mapStyleStandard: return 2
        case .readyFinal:                               return 3
        default:                                        return 0
        }
    }
}
