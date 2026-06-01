import Foundation

/// Derives the set of seat codes the user has already occupied across past
/// `Journey`s. Used by `WagonView` to render tiles in the `.previouslyUsed`
/// state — the wagon becomes a quiet memory of where the user has sat before.
enum SeatHistory {
    /// `journeys` is expected to be the full SwiftData-fetched list (or any
    /// filtered subset) — typically passed in directly from a `@Query` in the
    /// host view to avoid coupling to the store layer.
    static func usedSeatCodes(in journeys: [Journey]) -> Set<String> {
        Set(journeys.compactMap(\.seatCode))
    }
}