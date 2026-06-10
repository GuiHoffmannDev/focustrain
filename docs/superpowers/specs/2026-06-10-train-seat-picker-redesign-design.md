# Train Seat Picker Redesign — "Steam Train" Design

**Date:** 2026-06-10
**Status:** Approved by user
**Reference:** airplane seat-map screenshots (dark cabin, empty rounded-square seats,
aisle row numbers, seat-anchored focus modal, filled seat + white Confirm pill).
Adapted to a top-down **steam train** to match the FocusTrain identity.

## Goal

Rework `SeatPickerView` into a scrollable top-down steam train. The tapped seat
morphs into the focus-reason modal; the chosen mode's icon fills the seat; a white
Confirm pill triggers a fast "train departing upward" animation, then the existing
BoardingPass flow continues unchanged.

## Out of scope

- BoardingPass (print/tear), SessionView, ArrivalView — untouched.
- Data model changes: `FocusMode`, `CustomFocusMode`, `FocusModeStore`, `Ticket`,
  `SeatHistory` stay as they are.
- Light mode work (separate plan).

## 1. Screen composition

One vertical `ScrollView` over `FT.Palette.black` + the existing top radial
`brandRail` glow. The full train is drawn as one continuous composition:

1. **Steam locomotive** (top of scroll), top-down view:
   - Circular chimney with a `brandBrass` accent ring.
   - Long boiler with transverse band lines.
   - Driver's cab (rounded rectangle) at the rear of the locomotive.
   - Same visual idiom as the current shell: thin `textMuted` stroke +
     translucent `bgElevated` fill. No Liquid Glass (selective-glass policy).
2. **Coupling**: short connector between locomotive and carriage.
3. **Passenger carriage**: rounded-top body, **20 rows**, columns **A C | D F**
   with a central aisle. Per the reference:
   - Column letters (A C D F) as a header row inside the carriage top.
   - **Row number centered in the aisle** (moves from today's side labels).
   - Seats are clean rounded squares with **no letter inside**.
   - Rounded tail closes the body at the bottom of the scroll.
4. Back chevron in the toolbar exactly as today (plain `Button`, iOS 26 toolbar
   provides the glass chrome).

Content is roughly 3 screens tall; initial scroll position shows the locomotive
nose with the first rows entering from below.

## 2. Seat states (`SeatTile`)

Same footprint for all states; frosted material baseline (`ftGlassRounded`,
no `liquid`):

- **available** — empty frosted rounded square, subtle `textMuted` stroke.
- **previouslyUsed** — subtle `brandRail` tint, as today.
- **filled** (new, replaces `selected`) — solid fill with the chosen mode's
  `tint` + the mode's SF Symbol centered, `ink`-colored (reference image 5:
  cream seat with flower icon).

While the modal is open the tapped seat's grid slot stays empty (the tile *is*
the modal via the shared geometry).

## 3. Seat → modal morph (`FocusReasonCard`)

- Tap an available/previouslyUsed seat: light haptic; the tile grows into the
  modal card via **`matchedGeometryEffect`** (shared `@Namespace`).
- Card content: small "Seat: 12C" label, title "What do you want to focus?"
  (localized), and the existing **`FocusModeChips`** (Focus, Work, Meditate,
  Read, Exercise, custom modes with delete, and **+** opening the existing
  `CustomFocusModeSheet`).
- Card surface: frosted rounded card (cornerRadius 24 idiom from
  `SeatConfirmCard`); behind it a dimming scrim over the whole screen; user
  scrolling disabled while open.
- Card floats near the seat's on-screen position, clamped to safe bounds.
- **Tap scrim** → reverse morph, seat returns to its previous state, no selection.
- **Pick a chip** → haptic; card shrinks back into the seat, now **filled**
  (mode tint + icon). Creating a custom mode via "+" selects it and closes the
  same way.
- Tapping a different seat afterwards clears the previous fill and opens the
  modal on the new seat (single selection).

## 4. Confirm + departure animation

- When a seat is filled, a floating **white "Confirm" pill** appears at the
  bottom (reference image 5), replacing today's `CTAButton` "Depart" + 
  `SeatConfirmCard` arrangement.
- On Confirm: medium haptic → user scrolling disabled → **departure run**:
  - The entire train content translates **upward** via animated `.offset`
    (~1.4 s, easeIn ramp: heavy start, then full acceleration) until completely
    off-screen (content height + screen height).
  - During the run: thin vertical **speed lines** streaking downward
    (white, low opacity), **steam puffs** emitted from the chimney
    (small fading circles), and light haptics at increasing frequency.
- When the train clears the screen → set `pendingBoardingPass` and present
  **`BoardingPassView`** exactly as today (print + tear → `onDepart` →
  session starts).
- **Reduce Motion**: skip the run; simple crossfade to the BoardingPass.

## 5. Data & files

**Model:**
- `WagonLayout.standard`: rows `1...7` → `1...20`. Seat codes keep the
  `"12C"` format; historical codes (rows 01–07) remain valid for
  `SeatHistory.usedSeatCodes`.

**New files** (synced file groups — no pbxproj edits):
- `Features/TrainTicket/Views/Components/SteamLocomotiveView.swift`
  (locomotive + coupling shapes).
- `Features/TrainTicket/Views/Components/FocusReasonCard.swift` (morph modal).
- `Features/TrainTicket/Views/Components/SpeedLinesOverlay.swift`
  (speed lines + steam puffs + departure run driver).

**Modified:**
- `SeatPickerView.swift` — orchestration: namespace, modal state machine
  (idle → choosing(seat) → filled(seat, mode) → departing), Confirm pill,
  departure run, then BoardingPass cover (existing).
- `WagonView.swift` — 20 rows, aisle-centered row numbers, column header
  letters, carriage body + rounded tail.
- `SeatTile.swift` — `filled(mode tint + symbol)` state, no in-tile letter.

**Removed:**
- `SeatConfirmCard.swift` (superseded by `FocusReasonCard` + Confirm pill).

**Localization** (`Resources/Localizable.xcstrings`): new keys for the modal
seat label, modal title, and Confirm; retire unused `seatPicker.confirm.*` /
`seatPicker.depart` if nothing else references them.

## 6. Error handling & edge cases

- Custom-mode sheet dismissed without creating → modal stays open, no selection.
- Deleting the custom mode currently filling a seat → seat returns to available,
  Confirm pill hides.
- Back chevron always active except during the departure run.
- Departure run is one-shot; Confirm is disabled once tapped.

## 7. Testing

- `Tests/CitiesHarness` (SwiftPM): unit-test `WagonLayout` 20-row codes and
  compatibility of legacy seat codes.
- Visual/interaction: Xcode previews per component; simulator build with
  `CODE_SIGNING_ALLOWED=NO`.
- Manual checklist: morph open/cancel/pick, reselect another seat, custom mode
  add/delete, departure run → BoardingPass, Reduce Motion path.
