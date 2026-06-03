# Active Session Redesign — Phase 3 (Sound modal)

**Date:** 2026-06-03
**Scope:** `SessionView` (live ride) — replace the inline `SessionMusicMenu` with a full-screen Sound modal. UI + persistence only; no real audio playback yet.

## Goal

Convert today's mid-ride "music" button (which actually opens a vestigial `FocusScenario` picker) into a proper Sound modal that lets the traveller browse ambient sound cards, toggle a master Sound on/off, mute temporarily, and pick an AirPlay route. Real audio playback is deferred to Phase 4 — Phase 3 ships the surface and the persisted user intent so Phase 4 can plug an `AVAudioPlayer` into the controller without touching the views.

Reference: the user-supplied spec describing a sheet with a "Sound" header + green "♪ ON" pill, a row with a circular AirPlay button next to a long Mute pill, a "White Noise" section with a 2×2 grid of scenario cards (Airplane / Raindrop / Ocean Waves / Forest), and a "Focus Sound" section with a single disabled "Coming Soon" card.

## Non-goals (deferred to Phase 4+)

- Real audio playback (`AVAudioPlayer`, `AVAudioSession` configuration, background mode capability, interruption handling, route-change handling, crossfade between scenarios).
- Audio assets (`.mp3` / `.caf`) and their bundling.
- Real implementation of the "Focus Sound" category — the Coming Soon card stays a non-interactive placeholder.
- Volume slider.
- Layered / multi-track mixing.
- Auto-linking Sound to Rail Mode (the two stay independent).
- Persisting the sound selection inside `Ticket` (it lives in `UserDefaults` globally, not per-journey).
- Any refactor of `FocusScenario`, `SessionStore`, or `SessionViewModel` beyond the minimum needed for the new button.
- Any change to other screens (Home, Onboarding, History, Settings, DurationPicker, ArrivalView).

## Architecture

### New types

```
enum AmbientSoundCategory { case whiteNoise, focusSound }

enum AmbientSound: String, CaseIterable, Identifiable {
    case airplane, raindrop, ocean, forest

    var id: String { rawValue }
    var displayKey: String              // "sound.airplane.title" etc.
    var symbol: String                  // SF Symbol for the faint background glyph
    var gradient: [Color]               // warm brandBrass-derived gradient when ON
    var category: AmbientSoundCategory  // every Phase-3 case is .whiteNoise
}

@MainActor @Observable
final class AmbientSoundController {
    var selected: AmbientSound? { didSet { persistSelected() } }
    var isEnabled: Bool         { didSet { persistEnabled() } }
    var isMuted: Bool                    // ephemeral, not persisted

    var isPlaying: Bool { isEnabled && !isMuted && selected != nil }
}
```

`AmbientSoundController` mirrors `InAppTunnelController`: `@MainActor @Observable final class`, owned by `SessionView` via `@State`. All persistence is internal — the controller reads its initial state from `UserDefaults` in `init()` and writes back via the property `didSet`. The ephemeral `isMuted` lives only in memory and resets to `false` whenever a new session opens.

The computed `isPlaying` is the single source of truth for "would audio be coming out of the speaker right now?" — Phase 3 doesn't consume it, but Phase 4's audio engine will key off this exact predicate.

### Persistence keys

- `"ambientSoundSelection"` — `String`. Raw value of the selected `AmbientSound`, or `""` for no selection. Default `""`.
- `"ambientSoundEnabled"` — `Bool`. Master switch. Default `true`.

`isMuted` has no key — it is per-session ephemeral by design.

### SF Symbols per sound

| Sound | Symbol |
|---|---|
| `.airplane` | `airplane` |
| `.raindrop` | `cloud.rain.fill` |
| `.ocean` | `water.waves` |
| `.forest` | `tree.fill` |
| (Coming Soon placeholder) | `door.left.hand.closed` |

### Gradient palette

Active card background uses a brandBrass-derived warm gradient:

- Top-leading: `FT.Palette.brandBrass`
- Bottom-trailing: a darker amber/orange (~`Color(hex: 0xB87A3C)` — derived inline, no new palette token unless we end up reusing it elsewhere; flagged in code review)

Inactive cards use `FT.Palette.bgElevated` behind `.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))`, matching the iOS 26 chrome already adopted in Phase 2.

## SessionView changes

Replace this block:

```swift
SessionMusicMenu(
    scenario: $scenario,
    onSelect: { session.updateScenario($0) }
)
```

with:

```swift
SessionControlButton(
    systemName: "music.note",
    state: sound.selected != nil ? .active : .idle,
    accessibilityLabel: NSLocalizedString("session.sound.a11y", comment: ""),
    accessibilityValue: sound.selected?.rawValue ?? "off"
) {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    showSoundSheet = true
}
```

Add state to `SessionView`:

```swift
@State private var sound = AmbientSoundController()
@State private var showSoundSheet = false
```

Add at the bottom of `body`, alongside the existing `.sheet(isPresented: $showMapStyleSheet)`. Sheet presentation modifiers are applied on the `SoundSheet` instance inside the `.sheet(...)` closure (SwiftUI's standard pattern), not inside `SoundSheet`'s own body — keeps the view previewable in isolation:

```swift
.sheet(isPresented: $showSoundSheet) {
    SoundSheet(sound: sound)
        .presentationDetents([.large])
        .presentationBackground(.ultraThinMaterial)
        .presentationDragIndicator(.visible)
}
```

`SessionMusicMenu.swift` is **deleted** — vestigial mis-labelled picker that no longer has a caller.

Also delete in `SessionView`:

- `@State private var scenario: FocusScenario` (becomes dead state with the menu gone)
- The `_scenario = State(initialValue: FocusScenario(rawValue: ticket.scenario) ?? .forest)` line in `init`
- Nothing else changes — `scenario` was never read by the body itself, only fed into the deleted menu

`FocusScenario` itself stays — still used by Settings, Onboarding, History, ArrivalView, DurationPicker, TicketReveal. The visual scenario continues to be set pre-ride. Phase 3 simply stops exposing mid-ride scenario switching from the chrome. `SessionStore.updateScenario(_:)` becomes orphaned but stays in place — out of scope to remove per the "no SessionStore refactor" rule.

## View hierarchy

### `SoundSheet` (new file: `Features/FocusSession/Views/Components/SoundSheet.swift`)

```
NavigationStack
  ScrollView
    VStack(spacing: 20)
      HStack {                                                 // header row
        Text(NSLocalizedString("session.sound.title", ""))     //   "Sound" (huge, bold)
        Spacer()
        SoundMasterPill(isEnabled: $sound.isEnabled)
      }
      HStack(spacing: 12) {                                    // controls row
        AirPlayButton()                                        //   40pt circle, glass
        MutePill(isMuted: $sound.isMuted)                      //   takes remaining width
      }
      SoundSectionHeader(key: "session.sound.section.white")
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ForEach(AmbientSound.allCases.filter { $0.category == .whiteNoise }) { ambient in
            AmbientSoundCard(
                sound: ambient,
                isOn: sound.selected == ambient,
                isEnabled: sound.isEnabled,
                onTap: {
                    sound.selected = (sound.selected == ambient) ? nil : ambient
                }
            )
        }
      }
      SoundSectionHeader(key: "session.sound.section.focus")
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ComingSoonCard()
      }
      Spacer(minLength: 0)
    .padding(.horizontal, FT.Layout.sideMargin)
    .padding(.top, 8)
  .navigationBarTitleDisplayMode(.inline)
  .toolbar {
    ToolbarItem(placement: .topBarTrailing) { closeButton }
  }
```

Close button = the same X used in Phase 2's `MapStyle` sheet: 30pt circle, `xmark` glyph, `FT.Palette.bgElevated.opacity(0.6)` fill. Inlined inside `SoundSheet`'s `.toolbar { ToolbarItem(placement: .topBarTrailing) { ... } }`, same shape as in [SessionView.swift:219-231](FocusTrain/Features/FocusSession/Views/SessionView.swift#L219-L231). Not extracted into a shared component — wait until a 3rd callsite appears.

Sheet modifiers stay on the `SessionView` `.sheet(...)` call, not on `SoundSheet` itself (so previews stay simple).

### Component table

| Component | File | Responsibility |
|---|---|---|
| `SoundSheet` | `Features/FocusSession/Views/Components/SoundSheet.swift` | Modal container — header, controls, sections, grid, close button |
| `AmbientSoundCard` | `Features/FocusSession/Views/Components/AmbientSoundCard.swift` | 150×150 (approx; uses `aspectRatio(1, contentMode: .fit)`), 20pt radius, title top-leading bold, faint background glyph (≈12% opacity), ON/OFF label + dot bottom-trailing. Active state: warm brandBrass gradient + "ON" + white dot. Inactive: glass + "OFF" + gray dot. Inputs: `sound: AmbientSound`, `isOn: Bool`, `isEnabled: Bool` (parent dims to 50% via `.opacity` when `false`), `onTap: () -> Void`. No reference to the controller — pure presentation |
| `ComingSoonCard` | same file as `AmbientSoundCard`, as a sibling `struct` (not nested) | Visual disabled variant — "Coming Soon" title, `door.left.hand.closed` faint glyph, "OFF" fixed, `.allowsHitTesting(false)`, dim 0.5 opacity. No inputs |
| `SoundMasterPill` | `Features/FocusSession/Views/Components/SoundMasterPill.swift` | Compact pill ~64×32, music-note glyph + "ON"/"OFF". Active: `FT.Palette.success` fill, white glyph. Inactive: glass + textSecondary glyph. Toggles `controller.isEnabled` |
| `MutePill` | `Features/FocusSession/Views/Components/MutePill.swift` | Long pill, `speaker.slash`/`speaker.slash.fill` glyph + "Mute"/"Muted" label. Takes remaining width via `.frame(maxWidth: .infinity)`. Active (muted): glass + brightness up. Inactive: glass standard. Toggles `controller.isMuted` |
| `AirPlayButton` | `Features/FocusSession/Views/Components/AirPlayButton.swift` | `UIViewRepresentable` wrapping `AVRoutePickerView`. 40pt circle, glass background underneath. Tap opens the system route picker |
| `SoundSectionHeader` | private helper inside `SoundSheet.swift` (no separate file) | Bold ~13pt left-aligned `Text`, top inset 4pt, no decoration |

`SessionControlButton`, `SessionControlPill`, `MapStyleSelector`, `InAppTunnelController` — untouched.

`AVRoutePickerView` requires `import AVKit`. The wrapper exposes only the route picker glyph + glass background; the picker styles itself.

## Interaction matrix

| Action | Result |
|---|---|
| Tap chrome `music.note` button | Opens `SoundSheet`. Button shows `.active` state when `sound.selected != nil`, `.idle` otherwise |
| Tap an inactive card | That card becomes ON, any other card that was ON becomes OFF (single selection). `controller.selected` updates. Haptic: `.light` |
| Tap the active card | That card becomes OFF, `controller.selected = nil`. Haptic: `.light` |
| Tap any card while master pill is OFF | Same as above — `selected` still updates. The dim 50% opacity is a hint, not a lock. Phase 4's audio engine will check `isPlaying` (= `isEnabled && !isMuted && selected != nil`) before deciding to emit sound |
| Tap `SoundMasterPill` | Toggles `controller.isEnabled`. When `false`, the cards grid dims to ~50% opacity but stays tappable — selecting a card still updates `selected` (it just wouldn't play). Haptic: `.light` |
| Tap `MutePill` | Toggles `controller.isMuted`. Pill swaps glyph + label between "Mute" / "Muted". Cards and master pill unaffected. Haptic: `.light` |
| Tap `AirPlayButton` | Opens the native system route picker (handled entirely by `AVRoutePickerView`). No state of our own changes |
| Tap `ComingSoonCard` | Nothing. `.allowsHitTesting(false)` |
| Tap close button / swipe down | Sheet dismisses. `sound.selected` and `sound.isEnabled` persisted to `UserDefaults`. `sound.isMuted` stays in memory until the `SessionView` itself goes away |
| Reopen the sheet later in the same session | `selected`, `isEnabled` come from the controller's in-memory state (already in sync with UserDefaults); `isMuted` reflects whatever it was when the sheet was last closed (not reset on close — only on a new `SessionView` instance) |
| Open a new ride | New `SessionView` → new `AmbientSoundController()` → `isMuted` starts `false`, `isEnabled` and `selected` rehydrate from UserDefaults |

All toggles animate with `withAnimation(.spring(response: 0.4, dampingFraction: 0.82))` — same spring already used for `togglePause` and `cameraMode` in `SessionView`. Card on/off animates the gradient + dot color crossfade; pill toggles animate the fill swap.

## Card visual spec

```
┌──────────────────────────────┐
│ Airplane                     │   ← title, top-leading, bold ~17pt, white
│                              │
│              ✈ (faint, big,  │   ← background glyph, ~80pt, opacity 0.12,
│               bottom-right,  │     rotated -15° for character,
│               clipped)       │     `FT.Palette.white`
│                              │
│                              │
│                       ● ON   │   ← bottom-trailing: 6pt dot + label
└──────────────────────────────┘
   shape: RoundedRectangle(cornerRadius: 20)
   active fill: LinearGradient([brandBrass, darker amber], topLeading → bottomTrailing)
   inactive fill: bgElevated + .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
   active dot: white
   inactive dot: textMuted
   label "ON": white bold caption; "OFF": textMuted bold caption
   aspect ratio: 1:1
```

`ComingSoonCard` reuses the same shape but:

- Title "Coming Soon" instead of a sound name
- Glyph `door.left.hand.closed`, opacity 0.10
- "OFF" fixed, dot textMuted
- Outer opacity 0.5
- `.allowsHitTesting(false)`

## Strings (Localizable.xcstrings)

All new keys land via `NSLocalizedString(key, comment: "")` in code. The catalog itself gets updated manually in Xcode — the runtime falls back to the key string until the entry exists, which keeps the build green.

| Key | English | Portuguese |
|---|---|---|
| `session.sound.a11y` | Sound settings | Configurações de som |
| `session.sound.close` | Close | Fechar |
| `session.sound.title` | Sound | Som |
| `session.sound.master.on` | ON | LIGADO |
| `session.sound.master.off` | OFF | DESLIGADO |
| `session.sound.airplay.a11y` | AirPlay | AirPlay |
| `session.sound.mute` | Mute | Silenciar |
| `session.sound.muted` | Muted | Silenciado |
| `session.sound.section.white` | White Noise | Ruído Branco |
| `session.sound.section.focus` | Focus Sound | Som de Foco |
| `sound.airplane.title` | Airplane | Avião |
| `sound.raindrop.title` | Raindrop | Chuva |
| `sound.ocean.title` | Ocean Waves | Ondas do Mar |
| `sound.forest.title` | Forest | Floresta |
| `sound.comingsoon.title` | Coming Soon | Em Breve |
| `sound.state.on` | ON | LIGADO |
| `sound.state.off` | OFF | DESLIGADO |

The previous `session.music.a11y` key becomes orphaned. Leave it in the catalog (no compile-time pressure to remove); the next routine i18n sweep can prune it.

## Accessibility

- **Sheet root**: `.navigationBarTitleDisplayMode(.inline)`; the visual title "Sound" is rendered in the body (not the navigation bar), so the bar stays empty except for the close button.
- **Master pill**: `accessibilityLabel = "Sound"`, `accessibilityValue = isEnabled ? "on" : "off"`, `.accessibilityAddTraits(.isButton)`.
- **AirPlay**: `accessibilityLabel = "AirPlay"`, trait `.isButton`. The wrapper passes through any system labels.
- **Mute pill**: `accessibilityLabel = "Mute"`, `accessibilityValue = isMuted ? "muted" : "unmuted"`, trait `.isButton`.
- **Section headers**: `.accessibilityAddTraits(.isHeader)`.
- **Each `AmbientSoundCard`**: `accessibilityLabel = title`, `accessibilityValue = "on" / "off"`, trait `.isButton`. `accessibilityHint = "Double tap to select"` for inactive, `"Double tap to turn off"` for active.
- **`ComingSoonCard`**: `accessibilityLabel = "Coming Soon"`, `.accessibilityAddTraits(.isStaticText)`, no button trait.
- **VoiceOver order**: title → master pill → AirPlay → mute → "White Noise" header → 4 cards (row-major) → "Focus Sound" header → Coming Soon → close.

## Animations

| Transition | Curve |
|---|---|
| Sheet present / dismiss | System default (UIKit sheet animator) |
| Card on/off (gradient swap, dot/label crossfade) | `.spring(response: 0.4, dampingFraction: 0.82)` |
| Master pill toggle (fill swap) | `.spring(response: 0.4, dampingFraction: 0.82)` |
| Mute pill toggle (icon + label swap) | `.spring(response: 0.4, dampingFraction: 0.82)` |
| Cards dim when master OFF | `.easeInOut(duration: 0.2)` on `.opacity()` |

All taps fire `UIImpactFeedbackGenerator(style: .light).impactOccurred()` — paridade with the existing chrome.

## Sound × Rail Mode

Independent. Selecting a card does not enter Rail Mode; entering Rail Mode does not select a sound. The two controls remain orthogonal — same model as today's Tunnel toggle vs scenario picker.

## Testing

No XCTest target in the repo. Verification is:

1. `xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` — must finish with `BUILD SUCCEEDED` after every task.
2. `#Preview` blocks on every new component: `AmbientSoundCard` (both ON and OFF states + ComingSoon), `SoundMasterPill` (both states), `MutePill` (both states), `AirPlayButton` (single state), `SoundSheet` (full modal with a mock controller in two states: nothing selected / Airplane selected).
3. Manual smoke test on iPhone 17 Pro simulator: start a 1-minute ride → tap music.note chrome button → sheet opens at `.large` → tap each card and confirm single-selection (only one ON at a time) → tap master pill ON/OFF and confirm cards dim → tap mute pill and confirm glyph/label swap → tap AirPlay and confirm system route picker opens → close sheet → reopen → confirm selected card + master state persisted → end ride → start new ride → reopen sheet → confirm `isMuted` reset to false but selection + master persisted.

## Rollout

- Direct commits to `main` (user authorized — see Phase 1/2 rollout). One commit per task. No PR, no feature flag.
- Each task = build green + scoped diff. Phase 2's working tree (StarsBackground, GlobeHomeView, etc.) is pre-existing and out of scope — only files this Phase touches get staged.
- Plan file: `docs/superpowers/plans/2026-06-03-active-session-redesign-phase3-sound.md`, written next via `superpowers:writing-plans` and executed via `superpowers:subagent-driven-development` with pause-for-review between tasks.

## Open items

None — every ambiguity resolved during brainstorming. Brass-derived darker amber hex (used in the gradient) is a one-off inline `Color(hex:)`; if it shows up in 2+ places after this phase, promote to `FT.Palette.brandBrassDeep` in a follow-up.
