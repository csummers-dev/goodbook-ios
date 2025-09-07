# Contributing to Good Book iOS

Thanks for your interest in contributing!

## Workflow

- Default branch: `main`
- Branch off `main` using `feature/<branch-name>`
- Open a PR to `main`; CI must pass and a review from `@corywatch` is required

## Project generation (XcodeGen only)

This repo standardizes on XcodeGen. Do not commit the generated `.xcodeproj`.

1) Install XcodeGen:
```bash
brew install xcodegen
```

2) Generate the project:
```bash
xcodegen generate
open GoodBook.xcodeproj
```

## Build and test locally

```bash
xcodebuild -project GoodBook.xcodeproj -scheme GoodBook -sdk iphonesimulator -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /tmp/goodbook_dd test
```

## Code style and guidelines

- Swift 5.9+, SwiftUI, MVVM
- Prefer small, focused types and functions
- Clear naming over abbreviations; add concise doc comments where helpful
- Avoid side effects in initializers; inject dependencies

## CI

GitHub Actions runs unit and UI tests on PRs and pushes to `main` using a simulator. No Apple credentials are used; signing is disabled for the simulator.


