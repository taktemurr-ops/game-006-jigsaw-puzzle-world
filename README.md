# Game 006 — Jigsaw Puzzle World

**Game Studio 100 / Flutter / Android + iOS**

Expanded the existing repo's sliding puzzle prototype with **picture reconstruction** mechanics. The original `SlidingPuzzle` API is kept for existing tests.

## Implemented source features
- Original procedural art themes (mountains, ocean, garden, sunset): no externally licensed images needed.
- 2×2–6×6 responsive picture puzzles; drag two pieces to swap or tap sequentially.
- Deterministic seed, daily challenge (UTC), classic, timed, zen, and original sliding mode.
- Undo, free hint, optional complete artwork preview, pause, restart, stopwatch, time limit.
- Local autosave and restore, corrupted-save safety, best scores, settings/data deletion.
- Turkish/English/Arabic user copy, RTL, voiceover labels, optional number overlay and reduced-motion preference.
- Pure Dart rules engine, storage/widget tests, Android CI build, macOS iOS compile workflow.

## Run and verify
```bash
flutter create --platforms=android,ios --project-name game_006_jigsaw_puzzle_world .
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
# on a macOS environment:
flutter build ios --debug --no-codesign
```

## Release gates not claimed complete
- This patch is not a signed store-ready release. Real Android/iOS physical-device, crash, accessibility, battery, store screenshots and policy review are still required.
- No third-party analytics, advertisements or payments are enabled, and no purchase grants are simulated.
- `sound` preference records a user choice but audio output requires reviewed, licensed effects before enabling.
- GitHub CI and mobile builds must succeed before declaring release readiness.

This directory is a source overlay for the **existing** `taktemurr-ops/game-006-jigsaw-puzzle-world` repo. Only files in this overlay need replacement; preserve unrelated repo docs/tests.
