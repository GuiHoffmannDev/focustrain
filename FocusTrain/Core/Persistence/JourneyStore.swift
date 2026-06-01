import Foundation
import SwiftData

/// Stateless helpers for completed-journey persistence and streak math.
/// Views own the `@Query` / `ModelContext`; these are pure operations on top.
enum JourneyStore {
    static func save(_ ticket: Ticket, in context: ModelContext, completedAt: Date = .now) {
        let journey = Journey(ticket: ticket, completedAt: completedAt)
        context.insert(journey)
        try? context.save()
    }
}

/// Computes a consecutive-calendar-day streak from completed journeys.
enum StreakCalculator {
    /// Count of consecutive days (ending today or yesterday) with ≥1 journey.
    /// If the most recent journey is older than yesterday, the streak is 0.
    static func currentStreak(from journeys: [Journey], now: Date = .now, calendar: Calendar = .current) -> Int {
        guard !journeys.isEmpty else { return 0 }

        // Unique day-starts that have at least one journey.
        let days = Set(journeys.map { calendar.startOfDay(for: $0.date) })
        let today = calendar.startOfDay(for: now)

        // The streak must include today or yesterday to be "current".
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        var cursor: Date
        if days.contains(today) {
            cursor = today
        } else if days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
