# NUMBERING

NUMBERING is a Flutter number-puzzle collection with three continuously
playable solo games. It keeps the existing Bee House shell, authentication,
settings, audio, and visual design while replacing the game slot with the new
number logic.

## Highlights

- Formula Workshop: preserve digit order and build a valid equation
- Sequence Detective: infer the unique ordered starting pair
- Number Vault: reorder and combine every number to reach a target
- EASY / NORMAL / HARD progression across continuous rounds
- Seeded daily challenge rotating through the three games
- Ranking screens retained as offline template UI
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
local scores, settings, and daily practice remain available; social sign-in is
disabled. Providing only one value is treated as a configuration error.

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

Supabase is initialized only for authentication and session management. Database,
RPC, ranking, score submission, profile-table, and daily-challenge connections are
not included. Nicknames and scores are stored only on the local device.

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
# game_template
# numbering_flutter
