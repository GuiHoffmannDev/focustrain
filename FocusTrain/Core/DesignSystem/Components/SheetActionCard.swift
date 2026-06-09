import SwiftUI
import UIKit

/// One of the three stacked cards on the Home bottom (History / Trends /
/// Settings). A thin caller of `FTGlassCardButton` (Liquid Glass surface,
/// tappable, press-scales) — see `FTGlass.swift`.
struct SheetActionCard: View {
    let title: String
    let caption: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        FTGlassCardButton(title: title, caption: caption, systemImage: systemImage, action: action)
    }
}
