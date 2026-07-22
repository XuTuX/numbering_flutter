# NUMBERING

NUMBERING is a Flutter number-puzzle collection with three continuously
playable solo games with shared authentication, settings, audio, and a unified
visual design.

## Highlights

- Formula Workshop: preserve digit order and build a valid equation
- Sequence Detective: infer the unique ordered starting pair
- Number Vault: reorder and combine every number to reach a target
- EASY / NORMAL / HARD progression across continuous rounds
- Server-seeded official Numbering daily challenge
- Supabase-verified all-time, weekly, and daily rankings
- Responsive Flutter UI for iPhone and iPad
- Korean, English, Japanese, Simplified Chinese, and Hindi localization

## How to Play

Tap Play, select one of the three games, and solve rounds in order. Formula
Workshop and Number Vault advance as soon as the expression becomes valid;
Sequence Detective counts submitted attempts. Reset restores only the current
editor while preserving the problem and session progress.

## Technology

- Flutter / Dart
- Supabase Auth for Google / Apple login only; no Realtime multiplayer server
- GetX state and dependency management
- Shared Preferences for local progress and settings
- Google / Apple sign-in, share sheets, audio, haptics, and mobile ads

## Runtime Configuration

This app now expects runtime values through `--dart-define`.

Optional authentication values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

If both values are omitted, the app starts in offline guest mode. Gameplay,
local progress, settings, and daily practice remain available; social sign-in,
official score submission, and official rankings are disabled. Providing only
one value is treated as a configuration error.

Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## Google Sign-In Configuration

Google Sign-In client identifiers are configured natively:

- Android: `android/app/src/main/res/values/strings.xml`
- iOS: `ios/Runner/Info.plist`

## Android Signing

Release signing can be provided in either of these ways:

1. `android/key.properties`
2. Environment variables: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`

If signing values are missing, Gradle can still produce an unsigned release artifact for verification builds.

## Supabase Scope

When Supabase configuration is supplied, Numbering uses Supabase Auth plus
server-verified RPCs for normal best scores, the official daily challenge,
all-time rankings, daily rankings, and weekly best scores. The client submits
the completed expression rather than writing a trusted score directly. See
[`docs/numbering_supabase.md`](docs/numbering_supabase.md) for the validation and
retry rules.

## Verification

```bash
flutter analyze
flutter test
flutter build web --release
```

The NAN 2026 preparation audit on 2026-07-14 completed all three checks
successfully. The web build reports only Flutter's informational WebAssembly
compatibility note for GetX's current `dart:html` implementation.

## Source and Asset Notice

Source code is provided for review. Third-party packages remain under their
respective licenses. Before redistributing the project media independently,
confirm the authorship or license records for the files in `assets/icons/` and
`assets/bgm/`. The NAN 2026 asset checklist tracks the remaining evidence.
