# Game 006 — Quality / store acceptance matrix

Status: **development source**, not production release.

| Area | Required evidence |
|---|---|
| Mechanics | Existing sliding tests + new picture rules tests pass |
| Puzzle correctness | Shuffle permutations, undo, deterministic daily seeds, hint completion |
| Persistence | Offline restoration, corrupted-save recovery, delete-data behavior |
| Localization | Manual English/Turkish/Arabic layout, RTL screenshots |
| Accessibility | TalkBack/VoiceOver physical device, contrast, touch targets, reduced-motion review |
| Android | Flutter analyze, unit/widget tests, signed AAB, real-device smoke |
| iOS | macOS compile, simulator, device, signed IPA, App Store Connect review |
| Privacy | Confirm local-only operation; privacy disclosures and child-safety classification |
| Monetization | No ads/IAP enabled; adding one requires compliant consent and backend receipt validation |
| Content | Procedural artwork review, icon, screenshots, descriptions, music licensing |
| Stability | Crash-free smoke, 30-minute play, pause/resume, startup memory/performance |

Keep all gates open until evidence exists. Do not close the acceptance issue solely on a GitHub push.
