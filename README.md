# Good Book (iOS, SwiftUI)

[![iOS Build & Test](https://github.com/csummers-dev/goodbook-ios/actions/workflows/ios.yml/badge.svg?branch=main)](https://github.com/csummers-dev/goodbook-ios/actions/workflows/ios.yml)

An iOS Bible reading, journaling, and study app built with SwiftUI and MVVM.

## Vision

- Beautiful, clean, minimal Bible reading experience with no distractions.
- Absolutely no ads, telemetry, analytics, or tracking.
- Always free and open source.
- Private by default; your data lives on your device.

## Highlights

- Modular architecture: Models, Services, ViewModels, Views
- Local JSON Bible provider (sample ESV data) with robust bundle lookup
- Translation-agnostic highlights with color and optional notes
- Full-screen scrollable Reading view; toggle highlight visibility; translation switcher
- Highlights list (grouped), Settings (theme, font size)
- Privacy-first: no analytics or tracking; no third-party SDKs
- Offline-first: reading works without a network connection

## Project structure

- `GoodBook/` — application source
  - `App/` — entry point (`GoodBookApp`), environment wiring
  - `Models/` — domain models (`BibleBook`, `Highlight`, selection types, `Translation`)
  - `Services/` — data providers and persistence (`BibleDataProvider`, `HighlightStore`, `SettingsStore`)
  - `ViewModels/` — screen state (`ReadingViewModel`, `HighlightsListViewModel`)
  - `Views/` — SwiftUI screens (`ReadingView`, `ContentView`, `SettingsView`, etc.)
- `AppResources/` — bundled data and assets copied as a folder reference
  - `Bibles/<TRANSLATION>/<Book>.json` (e.g., `Bibles/ESV/John.json`)
- `project.yml` — XcodeGen manifest for deterministic project generation

## Requirements

- Xcode 16.x with iOS Simulator 18.x SDK
- iOS deployment target 17.0+
- Homebrew (for XcodeGen)

## Setup

1) Install XcodeGen:
```bash
brew install xcodegen
```

2) Generate the Xcode project:
```bash
xcodegen generate
```

3) Build and run on an iOS simulator:
```bash
xcodebuild -project GoodBook.xcodeproj -scheme GoodBook -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/goodbook_dd build
open GoodBook.xcodeproj
```

Note: This repository standardizes on XcodeGen. The generated `GoodBook.xcodeproj` is not tracked in git.

Note: This repository uses `GoodBook.xcodeproj` generated from `project.yml`. Legacy `BibleApp.xcodeproj` has been removed.

## Architecture

- SwiftUI + MVVM
  - Views render state and forward user intents
  - ViewModels orchestrate loading, persistence, and UI state
  - Services encapsulate IO (bundle JSON, user defaults, local files)

## Privacy

- No analytics, tracking, or third-party SDKs.
- No external network calls for core reading; content is bundled locally.
- Highlights and settings are stored on-device. Future cloud features will be opt-in.

- Services
  - `BibleDataProvider` protocol with `LocalJSONBibleProvider` implementation
    - Searches multiple bundle layouts: `Bibles/...`, `AppResources/Bibles/...`, and fallbacks
  - `HighlightStore` JSON persistence (Documents directory)
  - `SettingsStore` persists translation, theme, font size, and last-used highlight color via `UserDefaults`
  - `TranslationAvailabilityService` checks for `AppResources/Bibles/<TRANSLATION>/<BookId>.json` existence (no decoding) to drive disabled state

### Navigation: Sidebar drawer (Books)

- Overview: A swipeable left sidebar shows the canon grouped by sections: Old Testament, Apocrypha, and New Testament. Built with `ScrollView` + `LazyVStack` for precise control over gestures and animations.
- Gestures:
  - Open: toolbar button (top-left) or left-edge swipe (drag right)
  - Close: tap outside (scrim) or swipe drawer left
  - Animations: interactive spring; currently opens quickly (to be tuned later)
- Headers:
  - Rendered as pinned `Section` headers; remain visible while scrolling.
  - Uses system `secondaryLabel` color for reliable contrast across light/dark themes.
- Availability rules:
  - All sections and books are always shown for discoverability
  - Books without a bundled JSON for the current translation are disabled and greyed out (theme-aware gray)
  - Future: optionally show a hint when tapping disabled rows
- Titles:
  - The navigation title uses the catalog's full book name (e.g., `Genesis` instead of `Gen`).
  - A unit test verifies the `BibleCatalog.displayName(for:)` mapping to prevent regressions.
- Accessibility and testing:
  - Sidebar root: `sidebar.root`
  - Scrim: `sidebar.scrim`
  - Section headers: `sidebar.section.ot`, `sidebar.section.apocrypha`, `sidebar.section.nt`
  - Book row: `sidebar.book.<BookId>`
  - UI tests assert section headers exist to prevent regressions where headers are not visible.

## Feature status

- Completed
  - SwiftUI app scaffold with MVVM and clear module boundaries
  - App renaming and identifiers updated to Good Book / `GoodBook`
  - Reading view renders a book from bundled JSON via `LocalJSONBibleProvider`
  - Robust resource lookup supports `AppResources/Bibles/<TRANSLATION>/<Book>.json`
  - Translation picker in the toolbar; view model reloads on change (data loads when assets exist)
  - Highlight create/edit/delete with color coding and optional notes
    - Context menu per verse and bottom action bar after long-press selection
    - Toggle to show/hide highlights while reading
    - Translation-agnostic storage using `VerseRange`
    - Persistence to local JSON with `HighlightStore`
    - Remembers last-used highlight color for new highlights
    - Editor lifecycle: Save/Cancel dismiss the editor and return to Reading
  - Settings for preferred theme and reader font size (stored in `UserDefaults`)
  - Basic Highlights list view; basic navigation to Settings and Highlights

- In progress
  - Selection UX: refine long-press selection to true word-by-word and multi-verse ranges
    - Current state: verse-level approximation with action bar and notes option
  - Highlights list: grouping by book → chapter and filtering/sorting by color
  - Multi-translation datasets beyond ESV (switching is wired; assets to be added)
  - Navigator to open any book (single-book demo now; code prepared for expansion)

- Planned
  - Reader display modes: verse-by-verse and paragraph layout
  - Toggle to show/hide verse numbers
  - Words of Jesus styling (red or blue, configurable)
  - Cloud sync/backup for highlights and settings
  - Additional themes and font options; theme presets
  - Import/export of highlights and notes
  - Global search across text and notes; quick-jump to references
  - Full navigator UI for books/chapters/verses
  - Performance profiling with large datasets; memory-efficient rendering
  - Accessibility improvements (Dynamic Type, VoiceOver cues)
  - Unit/UI tests and snapshot tests for views

Notes: This section is intended to be living documentation. Maintain by moving items between lists as features ship or begin.

## Testing

- Targets
  - Unit: `GoodBookTests`
  - UI: `GoodBookUITests`
  - Both are configured in `project.yml` and included in the `GoodBook` scheme.

- Directory layout
  - `GoodBookTests/`
    - `Fixtures/` sample JSON (e.g., `John.json`)
    - `Doubles/` fakes/mocks (e.g., `FakeBibleDataProvider`)
    - `Unit/` test files (e.g., `ReadingViewModelTests`)
  - `GoodBookUITests/`
    - `Screens/` page objects (e.g., `ReadingScreen`)
    - `Flows/` end-to-end flows (e.g., `LaunchAndRenderFlowTests`)
    - `Utils/` shared helpers (e.g., `LaunchArguments`)

- Running tests
```bash
xcodegen generate
xcodebuild -project GoodBook.xcodeproj -scheme GoodBook -sdk iphonesimulator -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -derivedDataPath /tmp/goodbook_dd test
```

Local verification (2025-09-07):

- Built with `xcodegen generate` and `xcodebuild test`
- Unit tests: 8 passed
- UI tests: 3 passed
- Simulator: iPhone 16 (iOS 18.6)
- Commit: a47b509

- UI test mode
  - The app checks for `-uiTestMode` launch argument and resets highlights for deterministic runs.
  - Example in test: `app.launchArguments += ["-uiTestMode"]`.

- Accessibility identifiers
  - `reading.toggle.highlights` for the highlights toggle button
  - `reading.verse.<chapter>-<verse>` for individual verse rows
  - `reading.selection.notes` for the notes toggle in the selection bar
  - `reading.selection.highlight` for the highlight action in the selection bar
  - `editor.save` and `editor.cancel` for the editor toolbar buttons

## Data format

Path in app bundle (folder reference):
```
AppResources/Bibles/ESV/John.json
```

Schema:
```json
{
  "id": "John",
  "name": "John",
  "chapters": [
    {
      "number": 10,
      "verses": [
        { "number": 10, "text": "The thief comes only to steal and kill and destroy..." },
        { "number": 11, "text": "I am the good shepherd..." },
        { "number": 12, "text": "He who is a hired hand..." }
      ]
    }
  ]
}
```

Add more translations/books by placing additional JSON files under `AppResources/Bibles/<TRANSLATION>/`.

### Placeholder translations

To support UI development across multiple translations before full text is added, the app includes placeholder JSON files for all 66 canonical books across supported translations.

- Translations: `KJV`, `NKJV`, `ESV`, `NIV`, `CSB`, `NRSV`
- Location: `AppResources/Bibles/<TRANSLATION>/<BookId>.json` (e.g., `AppResources/Bibles/ESV/Gen.json`)
- Content: two stub verses in chapter 1 with marker text like `[Placeholder NIV] Genesis 1:1`
- Apocrypha: opt-in; currently only `Tobit (Tob)` seeded for demonstration

Loading behavior:

- The provider first looks for `AppResources/Bibles/<TRANSLATION>/<Book>.json`.
- If not found, it falls back to any available `<Book>.json` in the bundle, enabling development with a single translation.
- Errors are surfaced via a small banner in the Reading view when neither is available.

## Troubleshooting

- Simulator install says “Missing bundle ID”
  - Avoid naming the top-level folder `Resources` inside the .app (reserved semantics in some tools). This project uses `AppResources` copied as a folder reference.
  - Ensure `CFBundleIdentifier` and `CFBundleExecutable` are present in `GoodBook/Info.plist` (they are set via build settings and `$(EXECUTABLE_NAME)`).
  - Clean build and reinstall:
    ```bash
    xcodegen generate && xcodebuild -project GoodBook.xcodeproj -scheme GoodBook -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/goodbook_dd clean build
    xcrun simctl uninstall <UDID> com.cory.GoodBook
    xcrun simctl install <UDID> /tmp/goodbook_dd/Build/Products/Debug-iphonesimulator/GoodBook.app
    xcrun simctl launch <UDID> com.cory.GoodBook
    ```

- Reading view shows spinner only
  - Verify the currently selected translation has bundled data (start with ESV)
  - Check the small error banner at the top; if present, it will show the underlying error from the provider

- Simulator noise (safe to ignore)
  - `eligibility.plist` and CA Event logs are benign and unrelated to install or content loading

## Contributing notes

- Keep code modular and documented; prefer small focused types/functions
- Favor clear naming over abbreviations
- Avoid side effects in initializers; wire dependencies explicitly

## License

MIT
